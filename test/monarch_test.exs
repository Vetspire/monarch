defmodule MonarchTest do
  use Monarch.DataCase, async: true
  use Oban.Testing, repo: Monarch.Repo

  import Ecto.Query

  alias Monarch.Repo

  describe "Monarch.run/1" do
    test "detects and queues jobs" do
      Monarch.run(Monarch.Oban, "test")

      queued_jobs = all_enqueued(worker: Monarch.Worker)

      assert %Oban.Job{
               args: %{
                 "job" => "Elixir.MonarchTestEmptyJob",
                 "repo" => "Elixir.Monarch.Repo"
               },
               worker: "Monarch.Worker"
             } =
               Enum.find(queued_jobs, fn oban_job ->
                 oban_job.args["job"] == "Elixir.MonarchTestEmptyJob"
               end)

      assert %Oban.Job{
               args: %{
                 "job" => "Elixir.MonarchTestDeleteFakeJob",
                 "repo" => "Elixir.Monarch.Repo"
               },
               worker: "Monarch.Worker"
             } =
               Enum.find(queued_jobs, fn oban_job ->
                 oban_job.args["job"] == "Elixir.MonarchTestDeleteFakeJob"
               end)

      # In this test, "MonarchTestAlreadyCompletedJob" has not already been completed
      assert %Oban.Job{
               args: %{
                 "job" => "Elixir.MonarchTestAlreadyCompletedJob",
                 "repo" => "Elixir.Monarch.Repo"
               },
               worker: "Monarch.Worker"
             } =
               Enum.find(queued_jobs, fn oban_job ->
                 oban_job.args["job"] == "Elixir.MonarchTestAlreadyCompletedJob"
               end)

      scheduled_at_time = Timex.end_of_day(DateTime.utc_now())

      # A scheduled job will still be enqueued
      assert %Oban.Job{
               args: %{
                 "job" => "Elixir.MonarchTestScheduledJob",
                 "repo" => "Elixir.Monarch.Repo"
               },
               worker: "Monarch.Worker",
               scheduled_at: scheduled_at_time
             } =
               Enum.find(queued_jobs, fn oban_job ->
                 oban_job.args["job"] == "Elixir.MonarchTestScheduledJob"
               end)

      assert 4 = length(queued_jobs)
    end

    test "will not queue a job that has already been completed" do
      Repo.insert_all("monarch_jobs", [
        %{
          inserted_at: NaiveDateTime.truncate(DateTime.utc_now(), :second),
          name: "Elixir.MonarchTestAlreadyCompletedJob"
        }
      ])

      Monarch.run(Monarch.Oban, "test")

      assert 3 = length(all_enqueued(worker: Monarch.Worker))

      # Verify the update function of the completed job did not run which would have deleted the record
      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestAlreadyCompletedJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()
    end

    test "will not queue a job that has scheduled_at nil" do
      # Insert a record that would be caught by the job's query
      Repo.insert_all("monarch_jobs", [
        %{
          inserted_at: NaiveDateTime.truncate(DateTime.utc_now(), :second),
          name: "Elixir.AFakeJob"
        }
      ])

      Monarch.run(Monarch.Oban, "test")

      assert 4 = length(all_enqueued(worker: Monarch.Worker))

      # Verify the update function of the completed job did not run which would have deleted the record
      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.AFakeJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()

      # Verify a record does not get inserted for the manual job marking the job as completed
      assert 0 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestManualJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()
    end

    test "queues jobs that should be scheduled at in the future" do
      # Insert a record that would be caught by the job's query
      Repo.insert_all("monarch_jobs", [
        %{
          inserted_at: NaiveDateTime.truncate(DateTime.utc_now(), :second),
          name: "Elixir.AFakeJob"
        }
      ])

      Monarch.run(Monarch.Oban, "test")

      assert 4 = length(all_enqueued(worker: Monarch.Worker))

      # Verify the update function of the completed job did not run which would have deleted the record
      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.AFakeJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()

      # Verify a record does not get inserted for the scheduled job marking the job as completed
      assert 0 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestScheduledJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()
    end
  end

  describe "Monarch.Worker.perform/1" do
    test "inserts a record into `monarch_jobs` when job is completed" do
      assert :ok =
               Monarch.Worker.perform(%Oban.Job{
                 args: %{
                   "job" => "Elixir.MonarchTestEmptyJob",
                   "repo" => "Elixir.Monarch.Repo"
                 },
                 worker: "Monarch.Worker"
               })

      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestEmptyJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()
    end

    test "recurisvely performs jobs if there are still records to be updated" do
      # Insert a record to be caught by the job's query
      Repo.insert_all("monarch_jobs", [
        %{
          inserted_at: NaiveDateTime.truncate(DateTime.utc_now(), :second),
          name: "Elixir.AFakeJob"
        }
      ])

      assert :ok =
               Monarch.Worker.perform(%Oban.Job{
                 args: %{
                   "job" => "Elixir.MonarchTestDeleteFakeJob",
                   "repo" => "Elixir.Monarch.Repo"
                 },
                 worker: "Monarch.Worker"
               })

      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestDeleteFakeJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()

      # Verify the job's udpate function was successful and deleted the record
      assert 0 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.AFakeJob",
                 select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
               )
               |> Repo.all()
               |> length()
    end
  end
end
