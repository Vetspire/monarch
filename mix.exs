defmodule Monarch.MixProject do
  use Mix.Project

  def project do
    [
      app: :monarch,
      version: "0.1.0",
      elixir: "~> 1.15.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: ["lib/", "test/"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Monarch.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.14"},
      {:timex, "~> 3.7.6"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
