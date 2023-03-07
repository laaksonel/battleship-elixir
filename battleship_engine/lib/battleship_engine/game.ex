defmodule BattleshipEngine.Game do
  alias BattleshipEngine.{Game, Player}
  defstruct player1: :none, player2: :none

  use GenServer

  def add_player(pid, name) when not is_nil(name) do
    GenServer.call(pid, {:add_player, name})
  end

  def set_ship_coordinates(pid, player, ship_key, coordinates)
      when is_atom(player) and is_atom(ship_key) do
    GenServer.call(pid, {:set_ship_coordinates, player, ship_key, coordinates})
  end

  def guess_coordinate(pid, player, coordinate) when is_atom(player) and is_atom(coordinate) do
    GenServer.call(pid, {:guess, player, coordinate })
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

  def handle_call({:set_ship_coordinates, player, ship_key, coordinates}, _from, state) do
    state
    |> Map.get(player)
    |> Player.set_ship_coordinates(ship_key, coordinates)

    {:reply, :ok, state}
  end

  def handle_call({:guess, player, coordinate }, _from, state) do
    opponent = opponent(state, player)
    opponent_board = Player.get_board(opponent)
    response = Player.guess_coordinate(opponent_board, coordinate)

    {:reply, response, state}
  end

  defp opponent(state, :player1) do
    state.player2
  end

  defp opponent(state, :player2) do
    state.player1
  end
end
