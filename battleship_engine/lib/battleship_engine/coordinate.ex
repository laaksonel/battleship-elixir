defmodule BattleshipEngine.Coordinate do
  defstruct in_ship: :none, guessed?: false

  alias BattleshipEngine.Coordinate

  def start_link() do
    Agent.start_link(fn -> %Coordinate{} end)
  end

  def ship(coordinate) do
    Agent.get(coordinate, fn state -> state.in_ship end)
  end

  def in_ship(coordinate) do
    case ship(coordinate) do
      :none -> false
      _ -> true
    end
  end

  def guessed?(coordinate) do
    Agent.get(coordinate, fn state -> state.guessed? end)
  end

  def hit?(coordinate) do
    in_ship(coordinate) && guessed?(coordinate)
  end
end
