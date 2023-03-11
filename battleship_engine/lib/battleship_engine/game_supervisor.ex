defmodule BattleshipEngine.GameSupervisor do
  alias BattleshipEngine.Game
  use DynamicSupervisor

  def start_game(name) do
    DynamicSupervisor.start_child(__MODULE__, {Game, [name]})
  end

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
