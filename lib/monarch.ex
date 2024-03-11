defmodule Monarch do
  @moduledoc """
  Defines the Monarch behaviour.
  """

  import Ecto.Query

  alias Monarch.Worker

  @doc """
  The time the job should be scheduled to run at.

  If `scheduled_at` is in the past, the job will be scheduled as soon as possible the next time Monarch is run.
  If `scheduled_at` is nil, Monarch won't automatically enqueue jobs, and they will need to be manually enqueued.
  """
  @callback schedule_at :: DateTime.t() | nil

  @doc """
  A function which returns whether or not the worker should skip the operation.

  For example, this is useful when you want to run an Oban job on one environment but not another.
  """
  @callback skip :: boolean()

  @doc """
  A function which returns a list of records to be updated my a given job.

  Called as a way of stepping through large datasets (i.e. given an `Ecto.Queryable.t()` with predicates which
  get invalidated as `update/1` is run.

  Monarch jobs are deemed successful and complete once `query/0` returns an empty list.
  """
  @callback query :: [struct()]

  @doc """
  A function which takes the output of successive `query/1` calls and performs the given function
  against it.

  When used in tandem with `query/0`, allows stepping through large datasets (i.e. given an `Ecto.Queryable.t()` which
  invalidates predicates defined in `query/0`)
  """
  @callback update([struct()]) :: any()

  @doc """
  Queues up all pending jobs waiting to be run that have the Monarch behaviour implemented.
  """
  def run(oban, queue) do
    is_implemented = fn module ->
      __MODULE__ in List.wrap(module.module_info(:attributes)[:behaviour])
    end

    repo = Map.get(Oban.config(oban), :repo)

    modules =
      repo
      |> apply(:config, [])
      |> Keyword.get(:otp_app)
      |> :application.get_key(:modules)
      |> elem(1)

    jobs =
      modules
      |> Enum.filter(fn module -> is_implemented.(module) end)
      |> Enum.reject(fn module ->
        repo.exists?(
          from(job in "monarch_jobs", where: job.name == ^to_string(module), select: 1)
        ) or
          is_nil(module.schedule_at)
      end)

    for job <- jobs do
      Oban.insert(
        oban,
        Worker.new(%{job: job, repo: repo, schedule_at: job.schedule_at}, queue: queue)
      )
    end

    :ok
  end
end
