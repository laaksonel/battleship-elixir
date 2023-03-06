defmodule BattleshipEngine.ShipSet do
  alias BattleshipEngine.{Ship, ShipSet}

  # Weird ships aye?
  defstruct atoll: :none, dot: :none, l_shape: :none, s_shape: :none, square: :none

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
