defmodule Monarch do
  @moduledoc """
  Defines the Monarch behaviour.
  """

  import Ecto.Query

  alias Monarch.Worker

  @doc """
  The time the job should be scheduled to run at in the future in UTC.

  If `scheduled_at` is in the past, the job will be scheduled as soon as possible the next time Monarch is run.
  If `scheduled_at` is nil, Monarch won't automatically enqueue jobs, and they will need to be manually enqueued.
  """
  @callback scheduled_at :: DateTime.t() | nil

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
  Controls whether or not the job will run in a transaction
  """
  @callback transaction? :: boolean()

  @doc """
  Controls whether or not the job will snooze for a given number of seconds before running again.

  This is useful for jobs that should only run within a core set of business hours, or while external services
  are reachable.

  If `snooze?` is a falsey value, the job will not snooze.

  Example:

  ```elixir
  @impl Monarch
  def snooze? do
    if DateTime.utc_now().hour in 9..5 do
      3600 # snooze till the next hour
    end
  end
  ```

  Note that this callback is checked on every iteration of a backfill, so the runtime of your snooze function
  will impact the performance of your backfill.
  """
  @callback snooze? :: nil | false | integer()

  @optional_callbacks transaction?: 0, snooze?: 0

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

    jobs = Enum.filter(modules, fn module -> is_implemented.(module) end)

    repo.transaction(fn ->
      for job <- jobs,
          not is_nil(job.scheduled_at()),
          not completed?(repo, job),
          not running?(repo, job) do
        Oban.insert(
          oban,
          Worker.new(%{job: job, repo: repo}, queue: queue, scheduled_at: job.scheduled_at())
        )
      end
    end)

    :ok
  end

  @doc "Returns `true` if the given worker has completed, `false` otherwise"
  @spec completed?(repo :: module(), worker :: module()) :: boolean()
  def completed?(repo, worker) do
    repo.exists?(from(job in "monarch_jobs", where: job.name == ^to_string(worker), select: 1))
  end

  @doc "Returns `true` if the given worker is currently running, `false` otherwise"
  @spec running?(repo :: module(), worker :: module()) :: boolean()
  def running?(repo, worker) do
    repo.exists?(
      from(job in Oban.Job,
        where: job.args["job"] == ^to_string(worker),
        where: job.state not in ["completed", "discarded", "cancelled"],
        select: 1
      )
    )
  end
end
