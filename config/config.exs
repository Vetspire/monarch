import Config

config :monarch,
  environment: config_env()

config :monarch, Monarch.Repo,
  database: "monarch_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :monarch,
  ecto_repos: [Monarch.Repo]

config :monarch, Oban,
  name: Monarch.Oban,
  repo: Monarch.Repo,
  testing: :manual
