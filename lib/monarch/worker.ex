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
    worker = String.to_atom(job.args["job"])
    repo = String.to_atom(job.args["repo"])

    {:ok, {action, resp}} =
      cond do
        worker.skip() ->
          {:ok, {:halt, []}}

        function_exported?(worker, :snooze?, 0) && worker.snooze?() ->
          {:ok, {:snooze, worker.snooze?()}}

        Monarch.completed?(repo, worker) ->
          {:ok, {:halt, []}}

        true ->
          maybe_transaction(worker, repo, fn ->
            case worker.query() do
              [] ->
                :ok = log_completed!(repo, worker)
                {:halt, []}

              chunk ->
                if is_list(job.args["chunk"]) && job.args["chunk"] == chunk do
                  {:discard, chunk}
                else
                  worker.update(chunk)
                  {:cont, chunk}
                end
            end
          end)
      end

    case action do
      # Job finished successfully.
      :halt ->
        :ok

      # Recursively perform the Oban job if there are still records to be updated.
      # TODO: should we re-enqueue this working so it runs in a different pod?
      #       if so we'll have to do this differently.
      :cont ->
        perform(%{job | args: Map.put(job.args, "chunk", resp)})

      # Cycle was detected, no point in continuing.
      :discard ->
        {:discard, "Cycle detected. Discarding."}

      :snooze ->
        {:snooze, resp}
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

  defp maybe_transaction(worker, repo, lambda) do
    if function_exported?(worker, :transaction?, 0) && worker.transaction?() do
      repo.transaction(lambda)
    else
      {:ok, lambda.()}
    end
  end
end
