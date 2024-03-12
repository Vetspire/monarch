defmodule MonarchTestEmptyJob do
  @moduledoc """
  A module that implements a monarch job that returns no records to update.
  """

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: DateTime.utc_now()

  @impl Monarch
  def query, do: []

  @impl Monarch
  def update(_), do: :ok
end

defmodule MonarchTestDeleteFakeJob do
  @moduledoc """
  A module that implements a monarch job that will delete a record for
  `Elixir.AFakeJob` if one exists.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: DateTime.utc_now()

  @impl Monarch
  def query do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.all()
  end

  @impl Monarch
  def update(_) do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.delete_all()
  end
end

defmodule MonarchTestAlreadyCompletedJob do
  @moduledoc """
  A module that implements a monarch job that should already be
  completed. This job will delete a record for
  `Elixir.MonarchTestAlreadyCompletedJob` if one exists.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: DateTime.utc_now()

  @impl Monarch
  def query do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.MonarchTestAlreadyCompletedJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.all()
  end

  @impl Monarch
  def update(_) do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.MonarchTestAlreadyCompletedJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.delete_all()
  end
end

defmodule MonarchTestManualJob do
  @moduledoc """
  A module that implements a monarch job that should be manually run and should
  not automatically enqueue an Oban job.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: nil

  @impl Monarch
  def query do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.all()
  end

  @impl Monarch
  def update(_) do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.delete_all()
  end
end

defmodule MonarchTestScheduledFutureJob do
  @moduledoc """
  A module that implements a monarch job that should be scheduled at the end of the day.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: Timex.end_of_day(DateTime.utc_now())

  @impl Monarch
  def query do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.all()
  end

  @impl Monarch
  def update(_) do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.delete_all()
  end
end


defmodule MonarchTestScheduledPastJob do
  @moduledoc """
  A module that implements a monarch job that should be scheduled at the beginning of the day.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def scheduled_at, do: Timex.beginning_of_day(DateTime.utc_now())

  @impl Monarch
  def query do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.all()
  end

  @impl Monarch
  def update(_) do
    from(job in "monarch_jobs",
      where: job.name == "Elixir.AFakeJob",
      select: %{id: job.id, name: job.name, inserted_at: job.inserted_at}
    )
    |> Repo.delete_all()
  end
end
