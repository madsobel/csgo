defmodule CsgoWeb.PageController do
  use CsgoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
