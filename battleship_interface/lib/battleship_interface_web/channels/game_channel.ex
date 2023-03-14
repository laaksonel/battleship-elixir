defmodule BattleshipInterfaceWeb.GameChannel do
  alias BattleshipEngine.{GameSupervisor, Game}
  use BattleshipInterfaceWeb, :channel

  @impl true
  def join("game:" <> _player, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
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
      :error ->  {:reply, :error, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp via("game:" <> player), do: Game.via_tuple(player)
end
