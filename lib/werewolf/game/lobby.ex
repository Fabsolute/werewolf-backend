defmodule Werewolf.Game.Lobby do
  use Werewolf, :state

  alias Werewolf.Game.{Game, PlayerState}
  alias Werewolf.Util.Timer

  def handle_ready(state, player) do
    new_state =
      state
      |> Map.put(:players, Map.update!(state.players, player, &PlayerState.ready/1))

    self() <~ :check_game

    broadcast(new_state)
  end

  def handle_check_game(state) do
    state |> IO.inspect(label: :check_game)

    state =
      if map_size(state.players) > 1 and Enum.all?(state.players |> Map.values(), & &1.ready) do
        if state.timer == nil do
          state
          |> Map.put(
            :timer,
            start_timer("Game starting", 3000)
          )
        else
          state
        end
      else
        if state.timer != nil do
          Timer.stop(state.timer)
        end

        state |> Map.put(:timer, nil)
      end

    ok(state)
  end

  def handle_timer_message(state, _timer_pid, args) do
    state
    |> send_all(fn _player ->
      {:counter, args}
    end)

    ok(state)
  end
end
