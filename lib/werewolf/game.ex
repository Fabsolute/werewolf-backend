defmodule Werewolf.Game do
  defstruct id: nil, leader: nil, players: %{}, day: 0, is_night: false

  use Werewolf.FSM
  alias Werewolf.Supervisor
  alias Werewolf.Game.Lobby

  def game_init(room_id) do
    {Lobby, %__MODULE__{id: room_id}}
  end

  def join(room) do
    Supervisor.ensure_child_started(room)

    room <~ {:join, self()}
  end

  def list(room) do
    room <~ :list
  end

  def leave(room) do
    room <~ {:leave, self()}
  end

  def ready(room) do
    room <~ {:ready, self()}
  end
end
