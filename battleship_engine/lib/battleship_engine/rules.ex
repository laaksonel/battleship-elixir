defmodule BattleshipEngine.Rules do
  @behaviour :gen_statem

  def add_player(fsm) do
    :gen_statem.call(fsm, :add_player)
  end

  def callback_mode(), do: :state_functions

  def start_link() do
    :gen_statem.start_link(__MODULE__, :initialized, [])
  end

  def init(:initialized) do
    {:ok, :initialized, []}
  end

  def initialized({:call, from}, :add_player, state_data) do
    {:next_state, :players_set, state_data, {:reply, from, :ok}}
  end

  def initialized({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :initialized}}
  end

  def initialized({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def players_set({:call, from}, {:move_ship, player}, state_data) do
    case Map.get(state_data, player) do
      :ships_not_set ->
        {:keep_state_and_data, {:reply, from, :ok}}

      :ships_set ->
        {:keep_state_and_data, {:reply, from, :error}}
    end
  end

  def players_set({:call, from}, {:set_ships, player}, state_data) do
    state_data = Map.put(state_data, player, :ships_set)
    set_ships_reply(from, state_data, state_data.player1, state_data.player2)
  end

  def players_set({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :players_set}}
  end

  def players_set({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def player1_turn({:call, from}, {:guess_coordinate, :player1}, state_data) do
    {:next_state, :player2_turn, state_data, {:reply, from, :ok}}
  end

  def player1_turn({:call, from}, :win, state_data) do
    {:next_state, :game_over, state_data, {:reply, from, :ok}}
  end

  def player1_turn({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :player1_turn}}
  end

  def player1_turn({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def player2_turn({:call, from}, {:guess_coordinate, :player2}, state_data) do
    {:next_state, :player1_turn, state_data, {:reply, from, :ok}}
  end

  def player2_turn({:call, from}, :win, state_data) do
    {:next_state, :game_over, state_data, {:reply, from, :ok}}
  end

  def player2_turn({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :player2_turn}}
  end

  def player2_turn(_event, _caller_pid, state) do
    {:reply, {:error, :action_out_of_sequence}, :player2_turn, state}
  end

  def game_over({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_over}}
  end

  def game_over({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  defp set_ships_reply(from, state_data, status, status)
       when status == :ships_set do
    {:next_state, :player1_turn, state_data, {:reply, from, :ok}}
  end

  defp set_ships_reply(from, state_data, _, _) do
    {:keep_state, state_data, {:reply, from, :ok}}
  end
end
