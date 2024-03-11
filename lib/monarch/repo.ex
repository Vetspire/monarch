defmodule Monarch.Repo do
  use Ecto.Repo,
    otp_app: :monarch,
    adapter: Ecto.Adapters.Postgres
end
