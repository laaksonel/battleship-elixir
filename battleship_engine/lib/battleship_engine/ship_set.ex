defmodule BattleshipEngine.ShipSet do
  alias BattleshipEngine.{Ship, ShipSet, Coordinate}

  # Weird ships aye?
  defstruct atoll: :none, dot: :none, l_shape: :none, s_shape: :none, square: :none

  def set_ship_coordinates(ship_set, ship_key, new_coordinates) do
    ship = Agent.get(ship_set, fn state -> Map.get(state, ship_key) end)
    original_coordinates = Agent.get(ship, fn state -> state end)

    Ship.replace_coordinate(ship, new_coordinates)
    Coordinate.set_all_in_ship(original_coordinates, :none)
    Coordinate.set_all_in_ship(new_coordinates, ship)
  end

  def start_link() do
    Agent.start_link(fn -> initialized_set() end)
  end

  def sunken?(_ship_set, :none), do: false

  def sunken?(ship_set, ship_key) do
    ship_set
    |> Agent.get(fn state -> Map.get(state, ship_key) end)
    |> Ship.sunk?()
  end

  def all_sunk?(ship_set) do
    ships = Agent.get(ship_set, fn state -> state end)
    Enum.all?(keys(), fn ship_key -> Ship.sunk?(Map.get(ships, ship_key)) end)
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
