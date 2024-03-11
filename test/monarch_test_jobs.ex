defmodule MonarchTestEmptyJob do
  @moduledoc """
  This is a module that implements the Monarch behaviour for unit tests.
  """

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def schedule_at, do: DateTime.utc_now()

  @impl Monarch
  def query, do: []

  @impl Monarch
  def update(_), do: :ok
end

defmodule MonarchTestDeleteFakeJob do
  @moduledoc """
  This is a module that implements the Monarch behaviour for unit tests.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def schedule_at, do: DateTime.utc_now()

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
  This is a module that implements the Monarch behaviour for unit tests.
  """

  import Ecto.Query

  alias Monarch.Repo

  @behaviour Monarch

  @impl Monarch
  def skip, do: false

  @impl Monarch
  def schedule_at, do: DateTime.utc_now()

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
