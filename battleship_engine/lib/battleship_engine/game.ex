defmodule BattleshipEngine.Game do
  @timeout_ms 60 * 60 * 1000
  alias BattleshipEngine.{Game, Player, Rules}
  defstruct player1: :none, player2: :none, fsm: :none

  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  def add_player(pid, name) when not is_nil(name) do
    GenServer.call(pid, {:add_player, name})
  end

  def set_ship_coordinates(pid, player, ship_key, coordinates)
      when is_atom(player) and is_atom(ship_key) do
    GenServer.call(pid, {:set_ship_coordinates, player, ship_key, coordinates})
  end

  def set_ships(pid, player) when is_atom(player) do
    GenServer.call(pid, {:set_ships, player})
  end

  def guess_coordinate(pid, player, coordinate) when is_atom(player) and is_atom(coordinate) do
    GenServer.call(pid, {:guess, player, coordinate})
  end

  def start_link(name) when is_binary(name) and byte_size(name) > 0 do
    GenServer.start_link(__MODULE__, name, name: {:global, "game:#{name}"})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def via_tuple(name) do
    {:via, Registry, {Registry.Game, name}}
  end

  def init(name) do
    {:ok, player1} = Player.start_link(name)
    {:ok, player2} = Player.start_link()
    {:ok, fsm} = Rules.start_link()

    {:ok, %Game{player1: player1, player2: player2, fsm: fsm}, @timeout_ms}
  end

  def handle_call({:add_player, name}, _from, state) do
    Rules.add_player(state.fsm)
    |> add_player_reply(state, name)
  end

  def handle_call({:set_ship_coordinates, player, ship, coordinates}, _from, state) do
    Rules.move_ship(state.fsm, player)
    |> set_ship_coordinates_reply(player, ship, coordinates, state)
  end

  def handle_call({:set_ships, player}, _from, state) do
    reply = Rules.set_ships(state.fsm, player)
    {:reply, reply, state}
  end

  def handle_call({:guess, player, coordinate}, _from, state) do
    opponent = opponent(state, player)

    Rules.guess_coordinate(state.fsm, player)
    |> guess_reply(opponent.board, coordinate)
    |> sink_check(opponent, coordinate)
    |> win_check(opponent, state)
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  defp opponent(state, :player1) do
    state.player2
  end

  defp opponent(state, :player2) do
    state.player1
  end

  defp sink_check(:miss, _opponent, _coordinate) do
    {:miss, :none}
  end

  defp sink_check(:hit, opponent, coordinate) do
    ship_key = Player.sunken_ship(opponent, coordinate)
    {:hit, ship_key}
  end

  defp sink_check({:error, :action_out_of_sequence}, _opponent, _coordinate) do
    {:error, :action_out_of_sequence}
  end

  defp win_check({hit_or_miss, :none}, _opponent, state) do
    {:reply, {hit_or_miss, :none, :no_win}, state}
  end

  defp win_check({:hit, ship_key}, opponent, state) do
    win_status =
      case Player.win?(opponent) do
        true -> :win
        false -> :no_win
      end

    {:reply, {:hit, ship_key, win_status}, state}
  end

  defp win_check({:error, :action_out_of_sequence}, _opponent, state) do
    {:reply, {:error, :action_out_of_sequence}, state}
  end

  defp add_player_reply(:ok, state, name) do
    Player.set_name(state.player2, name)
    {:reply, :ok, state}
  end

  defp add_player_reply(reply, state, _name) do
    {:reply, reply, state}
  end

  defp set_ship_coordinates_reply(:ok, player, ship, coordinates, state) do
    Map.get(state, player)
    |> Player.set_ship_coordinates(ship, coordinates)

    {:reply, :ok, state}
  end

  defp set_ship_coordinates_reply(reply, _player, _ship, _coordinates, state) do
    {:reply, reply, state}
  end

  defp guess_reply(:ok, opponent_board, coordinate) do
    Player.guess_coordinate(opponent_board, coordinate)
  end

  defp guess_reply({:error, :action_out_of_sequence}, _opponent_board, _coordinate) do
    {:error, :action_out_of_sequence}
  end
end
