# https://www.reddit.com/r/GlobalOffensive/comments/cjhcpy/game_state_integration_a_very_large_and_indepth/
# https://github.com/zoidbergwill/csgo-overviews/blob/master/overviews/de_cache.jpg
defmodule CsgoWeb.MatchLive.Index do
  use CsgoWeb, :live_view

  alias Phoenix.PubSub
  alias Csgo.TimePresenter

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:time, "00:00")
      |> assign(:t_score, 0)
      |> assign(:ct_score, 0)
      |> assign(:ct_team, [])
      |> assign(:t_team, [])
      |> assign(:player_positions, %{})
    }
  end

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    if connected?(socket) do
      PubSub.subscribe(Csgo.PubSub, "match")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    msg
    |> Map.get("allplayers")
    |> IO.inspect(label: "🔥")

    {:noreply,
      socket
      |> update_time(msg)
      |> update_score(msg)
      |> update_teams(msg)
      |> update_player_positions(msg)
    }
  end

  defp update_time(socket, %{"phase_countdowns" => phase_countdowns}) do
    time = TimePresenter.convert_time(phase_countdowns["phase_ends_in"])
    assign(socket, :time, time)
  end

  defp update_score(socket, %{"map" => map}) do
    %{"team_ct" => %{"score" => ct_score}, "team_t" => %{"score" => t_score}} = map

    socket
    |> assign(:t_score, t_score)
    |> assign(:ct_score, ct_score)
  end

  defp update_teams(socket, %{"allplayers" => all_players}) do
    ct_team = find_team_players("CT", all_players)
    t_team = find_team_players("T", all_players)

    socket
    |> assign(:ct_team, ct_team)
    |> assign(:t_team, t_team)
  end

  defp update_player_positions(socket, %{"allplayers" => all_players}) do
    player_positions = Enum.reduce all_players, %{}, fn {_, player}, acc ->
      position =
        player["position"]
        |> String.split(", ")
        |> Enum.map(&String.to_float/1)
        |> List.to_tuple()

      if player_dead?(player) do
        acc
      else
        Map.put(acc, {player["team"], player["name"]}, position)
      end
    end

    assign(socket, :player_positions, player_positions)
  end

  defp render_player(team, player) do
    assigns = %{}
    ~H"""
    <div class={"px-4 py-2 #{player_team_color(team)}"}>
      <div class="flex items-center">
        <%= if player_dead?(player) do %>
          <svg class="h-4 w-4 mr-2" id="Icons" style="enable-background:new 0 0 32 32;" version="1.1" viewBox="0 0 32 32" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style type="text/css"> .st0{fill:none;stroke:#000000;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}</style><path class="st0" d="M28,14.8C28,8.3,22.6,3,16,3S4,8.3,4,14.8c0,1.3,0.2,2.5,0.6,3.6C4.2,19.1,4,19.9,4,20.7c0,2.6,2.1,4.7,4.8,4.7  c0.4,0,0.8-0.1,1.2-0.2V29h12v-3.7c0.4,0.1,0.8,0.2,1.2,0.2c2.7,0,4.8-2.1,4.8-4.7c0-0.8-0.2-1.6-0.6-2.3C27.8,17.3,28,16.1,28,14.8  z"/><polyline class="st0" points="18,24 16,22 14,24 "/><circle class="st0" cx="20.5" cy="18.5" r="2.5"/><circle class="st0" cx="11.5" cy="18.5" r="2.5"/></svg>
        <% end %>
        <span class={if player_dead?(player), do: "line-through"}><%= player["name"] %></span>
      </div>
      <div class="flex items-center gap-4 justify-between text-sm">
        <div class="flex items-center gap-4">
          <span>
            <strong>HP:</strong>
            <%= player["state"]["health"] %>
          </span>
          <span>
            <strong>AR:</strong>
            <%= player["state"]["armor"] %>
          </span>
          <span>
            <strong>$:</strong>
            <%= player["state"]["money"] %>
          </span>
        </div>
        <div class="flex items-center gap-4">
          <span>
            <strong>K:</strong>
            <%= player["match_stats"]["kills"] %>
          </span>
          <span>
            <strong>D:</strong>
            <%= player["match_stats"]["deaths"] %>
          </span>
          <span>
            <strong>A:</strong>
            <%= player["match_stats"]["assists"] %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp render_player_position({team, _name}, player_position) do
    assigns = %{}
    ~H"""
    <span class={"transition-all absolute h-4 w-4 rounded-full #{player_team_color(team)}"} style={calculate_player_position_style(player_position)}></span>
    """
  end

  defp calculate_player_position_style({x, y, _z}) do
    "left: #{((x - -2476) / 4.8) / 2}px; top: #{(1024 - ((y + (3239 / 2.4)) / 4.4)) / 2}px;"
  end
  defp player_team_color("CT"), do: "bg-blue-400"
  defp player_team_color("T"), do: "bg-orange-400"

  defp find_team_players(team, players) do
    Enum.reduce players, [], fn {_, player}, acc ->
      if player["team"] == team do
        [player | acc]
      else
        acc
      end
    end
  end

  defp player_dead?(player) do
    player["state"]["health"] == 0
  end
end
