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

    self() <~ :check_start

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

  # def handle_cast(:list, state) do
  #   change_state(Game)
  #   ok(state)
  # end

  def handle_cast(:check_start, state) do
    counter =
      if map_size(state.players) > 1 and Enum.all?(state.players |> Map.values(), & &1.ready) do
        delay({:counter, 3}, 1000)
        3
      end

    ok(state |> Map.put(:counter, counter))
  end

  def handle_cast(:broadcast_state, state) do
    state
    |> send_all(&{:state_changed, safe(state, &1)})

    ok(state)
  end

  def handle_info({:counter, 0}, state) do
    change_state(Game)
    ok(state |> Map.put(:counter, nil))
  end

  def handle_info({:counter, n}, state) do
    state
    |> send_all(fn _player -> {:counter, n} end)

    delay({:counter, n - 1}, 1000)

    ok(state |> Map.put(:counter, n))
  end

  defp broadcast(state) do
    self() <~ :broadcast_state

    ok(state)
  end
end
