defmodule Monarch.Worker do
  @moduledoc """
  Defines the Monarch Worker for running Oban jobs.
  """

  use Oban.Worker

  def perform(job) do
    worker = String.to_existing_atom(job.args["job"])
    repo = String.to_existing_atom(job.args["repo"])

    # Wraps a chunk of records to be updated in a transaction
    {:ok, action} =
      if apply(worker, :skip, []) do
        {:ok, :halt}
      else
        repo.transaction(fn ->
          case apply(worker, :query, []) do
            [] ->
              :halt

            chunk ->
              apply(worker, :update, [chunk])
              :cont
          end
        end)
      end

    # Recursively perform the Oban job if there are still records to be updated.
    if action == :halt do
      {1, _} =
        repo.insert_all("monarch_jobs", [
          %{
            inserted_at:
              DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second),
            name: to_string(worker)
          }
        ])

      :ok
    else
      perform(job)
    end
  end
end
