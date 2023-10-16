defmodule Werewolf.Game.State.Lobby do
  use Werewolf.FSM.State
  alias Werewolf.Game.{State.Game, PlayerState}

  def handle_cast({:join, player}, state) do
    leader = if state.leader == nil, do: player, else: state.leader

    ok(
      state
      |> Map.put(:players, Map.put(state.players, player, PlayerState.new()))
      |> Map.put(:leader, leader)
    )
  end

  def handle_cast({:ready, player}, state) do
    new_state =
      state
      |> Map.put(:players, Map.update!(state.players, player, &PlayerState.ready/1))

    IO.inspect(new_state, label: :new_state_after_ready)
    # todo broadcast the updates!
    ok(new_state)
  end

  def handle_cast({:leave, player}, state) do
    new_player_list = Map.delete(state.players, player)

    new_state =
      state
      |> Map.put(:players, new_player_list)

    if new_player_list == %{} do
      stop(new_state)
    else
      ok(new_state)
    end
  end

  def handle_message(:list, state) do
    state.players |> IO.inspect(label: :players)
    change_state(Game)
    ok(state)
  end
end
