defmodule Monarch.Repo.Migrations.AddMonarchJobs do
  use Ecto.Migration

  def up, do: Monarch.Migrations.up(version: 1)
  def down, do: Monarch.Migrations.down(version: 1)
end
