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
end
