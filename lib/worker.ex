defmodule Monarch.Worker do
  @moduledoc """
  Defines the Monarch Worker for running Oban jobs.
  """

  use Oban.Worker,
    unique: [
      fields: [:args, :worker],
      keys: [:job, :repo]
    ]

  @impl Oban.Worker
  def perform(job) do
    worker = String.to_existing_atom(job.args["job"])
    repo = String.to_existing_atom(job.args["repo"])

    # Wraps a chunk of records to be updated in a transaction
    {:ok, action} =
      cond do
        apply(worker, :skip, []) ->
          {:ok, :halt}

        Monarch.completed?(repo, worker) ->
          {:ok, :halt}

        true ->
          repo.transaction(fn ->
            case apply(worker, :query, []) do
              [] ->
                :ok = log_completed!(repo, worker)
                {:ok, :halt}

              chunk ->
                apply(worker, :update, [chunk])
                {:ok, :cont}
            end
          end)
      end

    # Recursively perform the Oban job if there are still records to be updated.
    if action == :halt do
      :ok
    else
      perform(job)
    end
  end

  defp log_completed!(repo, worker) do
    {1, _} =
      repo.insert_all("monarch_jobs", [
        %{
          inserted_at:
            DateTime.utc_now()
            |> DateTime.to_naive()
            |> NaiveDateTime.truncate(:second),
          name: to_string(worker)
        }
      ])

    :ok
  end
end
