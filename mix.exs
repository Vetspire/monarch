defmodule Monarch.MixProject do
  use Mix.Project

  def project do
    [
      app: :monarch,
      version: "0.1.3",
      elixir: "~> 1.17.2",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: ["lib/", "test/"],
      deps: deps(),
      docs: [main: "Monarch"],
      source_url: "https://github.com/vetspire/monarch",
      homepage_url: "https://github.com/vetspire/monarch",
      package: [licenses: ["MIT"], links: %{"GitHub" => "https://github.com/vetspire/monarch"}],
      description: "Simple framework for defining and running data migrations and backfills.",
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
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
      {:timex, "~> 3.7.6"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      lint: [
        "format --check-formatted --dry-run",
        "credo --strict",
        "compile --warnings-as-errors",
        "dialyzer"
      ]
    ]
  end
end
