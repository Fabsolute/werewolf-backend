defmodule Werewolf.Game.Lobby do
  use Werewolf, :state

  alias Werewolf.Game.{Game, PlayerState}

  def handle_cast({:join, player, username}, state) do
    leader = if state.leader == nil, do: player, else: state.leader

    broadcast(
      state
      |> Map.put(:players, Map.put(state.players, player, PlayerState.new(username)))
      |> Map.put(:leader, leader)
    )
  end

  def handle_cast({:ready, player}, state) do
    new_state =
      state
      |> Map.put(:players, Map.update!(state.players, player, &PlayerState.ready/1))

    broadcast(new_state)
  end

  def handle_cast({:leave, player}, state) do
    new_player_list = Map.delete(state.players, player)

    new_state =
      state
      |> Map.put(:players, new_player_list)

    if new_player_list == %{} do
      stop(new_state)
    else
      broadcast(new_state)
    end
  end

  def handle_cast(:list, state) do
    change_state(Game)
    ok(state)
  end

  def handle_cast(:broadcast_state, state) do
    clean_state =
      %{
        day: state.day,
        is_night: state.is_night,
        leader: state.leader,
        players: state.players |> Map.to_list() |> Enum.map(&PlayerState.safe/1)
      }

    state.players
    |> Map.keys()
    |> Enum.each(fn player ->
      player <~ {:state_changed, clean_state}
    end)

    ok(state)
  end

  defp broadcast(state) do
    self() <~ :broadcast_state

    ok(state)
  end
end
