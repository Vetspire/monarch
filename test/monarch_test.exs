defmodule MonarchTest do
  use Monarch.DataCase, async: true
  use Oban.Testing, repo: Monarch.Repo

  import Ecto.Query

  alias Monarch.Repo

  describe "Monarch.run/1" do
    test "detects and queues job" do
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

      assert 3 = length(queued_jobs)
    end

    test "will not queue a job that has already been completed" do
      Repo.insert_all("monarch_jobs", [
        %{
          inserted_at: NaiveDateTime.truncate(DateTime.utc_now(), :second),
          name: "Elixir.MonarchTestAlreadyCompletedJob"
        }
      ])

      Monarch.run(Monarch.Oban, "test")

      assert 2 = length(all_enqueued(worker: Monarch.Worker))

      # Verify the update function of the completed job did not run which would have deleted the record
      assert 1 =
               from(job in "monarch_jobs",
                 where: job.name == "Elixir.MonarchTestAlreadyCompletedJob",
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
