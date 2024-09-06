defmodule Monarch.Application do
  @moduledoc false

  use Application

  # coveralls-ignore-start
  @impl Application
  def start(_type, _args) do
    children =
      if Application.get_env(:monarch, :environment) == :test do
        [
          Monarch.Repo,
          {Oban, Application.get_env(:monarch, Oban)}
        ]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: Monarch.Supervisor)
  end
end
