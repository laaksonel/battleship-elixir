defmodule BattleshipEngine.ShipSet do
  alias BattleshipEngine.{Ship, ShipSet, Coordinate}

  # Weird ships aye?
  defstruct atoll: :none, dot: :none, l_shape: :none, s_shape: :none, square: :none

  def set_ship_coordinates(ship_set, ship, new_coordinates) do
    ship = Agent.get(ship_set, fn state -> Map.get(state, ship) end)
    original_coordinates = Agent.get(ship, fn state -> state end)

    Ship.replace_coordinate(ship, new_coordinates)
    Coordinate.set_all_in_ship(original_coordinates, :none)
    Coordinate.set_all_in_ship(new_coordinates, ship)
  end

  def start_link() do
    Agent.start_link(fn -> initialized_set() end)
  end

  defp initialized_set() do
    Enum.reduce(keys(), %ShipSet{}, fn key, set ->
      {:ok, ship} = Ship.start_link()
      Map.put(set, key, ship)
    end)
  end

  defp keys() do
    %ShipSet{}
    |> Map.from_struct()
    |> Map.keys()
  end
end
