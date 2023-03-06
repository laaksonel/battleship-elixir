defmodule BattleshipEngine.Ship do
  alias BattleshipEngine.Coordinate

  def start_link() do
    Agent.start_link(fn -> [] end)
  end

  def replace_coordinate(ship, coordinates) when is_list(coordinates) do
    Agent.update(ship, fn _state -> coordinates end)
  end

  def sunk?(ship) do
    ship
    |> Agent.get(fn state -> state end)
    |> Enum.all?(fn coord -> Coordinate.hit?(coord) end)
  end
end

