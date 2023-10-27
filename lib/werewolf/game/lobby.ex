defmodule Werewolf.Game.Lobby do
  use Werewolf, :state

  alias Werewolf.Game.{Game, PlayerState}

  def handle_ready(state, player) do
    new_state =
      state
      |> Map.put(:players, Map.update!(state.players, player, &PlayerState.ready/1))

    self() <~ :check_start

    broadcast(new_state)
  end

  def handle_check_start(state) do
    state =
      if map_size(state.players) > 1 and Enum.all?(state.players |> Map.values(), & &1.ready) do
        state |> Map.put(:counter, 3) |> handle_counter() |> elem(1)
      else
        state
      end

    ok(state)
  end

  def handle_counter(state) do
    state
    |> send_all(fn _player -> {:counter, state.counter} end)

    if state.counter == 0 do
      change_state(Game)
    else
      delay(:counter, 1000)
    end

    ok(state |> Map.put(:counter, state.counter - 1))
  end
end
