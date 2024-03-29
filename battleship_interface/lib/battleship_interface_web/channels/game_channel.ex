defmodule BattleshipInterfaceWeb.GameChannel do
  alias BattleshipInterfaceWeb.Presence
  alias BattleshipEngine.{GameSupervisor, Game}
  use BattleshipInterfaceWeb, :channel

  @impl true
  def join("game:" <> _player, %{"screen_name" => screen_name}, socket) do
    if authorized?(socket, screen_name) do
      send(self(), {:after_join, screen_name})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info({:after_join, screen_name}, socket) do
    {:ok, _} =
      BattleshipInterfaceWeb.Presence.track(socket, screen_name, %{
        online_at: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  def handle_in("show_subscribers", _payload, socket) do
    broadcast!(socket, "subscribers", Presence.list(socket))
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("hello", payload, socket) do
    # push(socket, "said_hello", payload)
    broadcast!(socket, "said_hello", payload)
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("new_game", _payload, socket) do
    "game:" <> player = socket.topic

    case GameSupervisor.start_game(player) do
      {:ok, _pid} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player, socket) do
    case Game.add_player(via(socket.topic), player) do
      :ok -> broadcast!(socket, "player_added", %{message: "New player joined: " <> player})
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
      :error -> {:reply, :error, socket}
    end
  end

  def handle_in("position_ship", payload, socket) do
    %{
      "player" => player,
      "ship" => ship,
      "coordinate" => coordinate
    } = payload

    player = String.to_existing_atom(player)
    ship = String.to_existing_atom(ship)

    case Game.set_ship_coordinates(via(socket.topic), player, ship, coordinate) do
      :ok -> {:reply, :ok, socket}
      _ -> {:reply, :error, socket}
    end
  end

  def handle_in("set_ships", player, socket) do
    player = String.to_existing_atom(player)

    case Game.set_ships(via(socket.topic), player) do
      {:ok, board} ->
        broadcast!(socket, "player_set_ships", %{player: player})
        {:reply, {:ok, %{board: board}}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("guess_coordinate", params, socket) do
    %{"player" => player, "coordinate" => coordinate} = params
    player = String.to_existing_atom(player)

    case Game.guess_coordinate(via(socket.topic), player, coordinate) do
      {:hit, ship, win} ->
        result = %{hit: true, ship: ship, win: win}

        broadcast!(socket, "player_guessed_coordinate", %{
          player: player,
          coordinate: coordinate,
          result: result
        })

        {:noreply, socket}

      {:miss, ship, win} ->
        result = %{hit: false, ship: ship, win: win}

        broadcast!(socket, "player_guessed_coordinate", %{
          player: player,
          coordinate: coordinate,
          result: result
        })

        {:noreply, socket}

      :error ->
        {:reply, {:error, %{player: player, reason: "Not your turn."}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{player: player, reason: reason}}, socket}
    end
  end

  defp via("game:" <> player), do: Game.via_tuple(player)

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end

  defp existing_player?(socket, screen_name) do
    socket
    |> Presence.list()
    |> Map.has_key?(screen_name)
  end

  defp authorized?(socket, screen_name) do
    number_of_players(socket) < 2 && !existing_player?(socket, screen_name)
  end
end
