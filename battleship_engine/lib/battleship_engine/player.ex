defmodule BattleshipEngine.Player do
  alias BattleshipEngine.{ShipSet, Board, Player}
  defstruct name: :none, board: :none, ship_set: :none

  def start_link(name \\ :none) do
    {:ok, board} = Board.start_link()
    {:ok, ship_set} = ShipSet.start_link()
    Agent.start_link(fn -> %Player{name: name, board: board, ship_set: ship_set} end)
  end

  def set_name(player, name) do
    Agent.update(player, fn player -> Map.put(player, :name, name) end)
  end

  def set_ship_coordinates(player, ship, coordinates) do
    board = get_board(player)
    ship_set = get_ship_set(player)

    new_coordinates = convert_coordinates(board, coordinates)
    ShipSet.set_ship_coordinates(ship_set, ship, new_coordinates)
  end

  def get_board(player) do
    Agent.get(player, fn state -> state.board end)
  end

  def get_ship_set(player) do
    Agent.get(player, fn state -> state.ship_set end)
  end

  defp convert_coordinates(board, coordinates) do
    Enum.map(coordinates, fn coord -> convert_coordinate(board, coord) end)
  end

  defp convert_coordinate(board, coordinate) when is_atom(coordinate) do
    Board.get_coordinate(board, coordinate)
  end

  defp convert_coordinate(_board, coordinate) when is_pid(coordinate) do
    coordinate
  end
  
end
