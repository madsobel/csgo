defmodule Csgo.Repo do
  use Ecto.Repo,
    otp_app: :csgo,
    adapter: Ecto.Adapters.Postgres
end
