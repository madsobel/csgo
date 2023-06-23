defmodule CsgoWeb.MatchController do
  use CsgoWeb, :controller

  alias Phoenix.PubSub

  def create(conn, params) do
    PubSub.broadcast(Csgo.PubSub, "match", params)
    json(conn, %{status: :ok})
  end
end
