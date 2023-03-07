defmodule BattleshipEngine.Game do
  alias BattleshipEngine.{Game, Player}
  defstruct player1: :none, player2: :none

  use GenServer

  def add_player(pid, name) when not is_nil(name) do
    GenServer.call(pid, {:add_player, name})
  end

  def set_ship_coordinates(pid, player, ship, coordinates)
      when is_atom(player) and is_atom(ship) do
    GenServer.call(pid, {:set_ship_coordinates, player, ship, coordinates})
  end

  def start_link(name) when not is_nil(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def init(name) do
    {:ok, player1} = Player.start_link(name)
    {:ok, player2} = Player.start_link()

    {:ok, %Game{player1: player1, player2: player2}}
  end

  def handle_call({:add_player, name}, _from, state) do
    Player.set_name(state.player2, name)
    {:reply, :ok, state}
  end

  def handle_call({:set_ship_coordinates, player, ship, coordinates}, _from, state) do
    state
    |> Map.get(player)
    |> Player.set_ship_coordinates(ship, coordinates)

    {:reply, :ok, state}
  end
end
