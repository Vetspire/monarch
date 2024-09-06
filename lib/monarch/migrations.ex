defmodule Monarch.Migrations do
  @moduledoc """
  This defines the migration for creating the necessary table `monarch_jobs` to use the Monarch behaviour.
  """

  use Ecto.Migration

  def up(version: 1) do
    create table(:monarch_jobs) do
      add(:name, :string, null: false)
      add(:inserted_at, :utc_datetime, null: false)
    end

    create(unique_index(:monarch_jobs, [:name]))
    create(index(:monarch_jobs, [:inserted_at]))
  end

  def down(version: 1) do
    drop(table(:monarch_jobs))
  end
end
