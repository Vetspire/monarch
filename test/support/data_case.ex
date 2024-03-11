defmodule Monarch.DataCase do
  @moduledoc """
  Helper module to set up test cases.
  """

  use ExUnit.CaseTemplate

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Monarch.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Monarch.Repo, {:shared, self()})
    end

    :ok
  end
end
