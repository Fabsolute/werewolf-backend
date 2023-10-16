defmodule Werewolf.Game.State.Game do
  use Werewolf.FSM.State
  alias Werewolf.Game.State.Lobby

  def handle_cast(:list, state) do
    IO.inspect("Hey", label: :game)
    change_state(Lobby)
    ok(state)
  end
end
