defmodule Werewolf.Game do
  defstruct id: nil, leader: nil, players: %{}, day: 0, is_night: false

  use Werewolf, :fsm

  def game_init(room_id) do
    {Werewolf.Game.Lobby, %__MODULE__{id: room_id}}
  end

  def join({:room, room_id} = room) do
    Werewolf.Supervisor.ensure_child_started(room_id)

    room <~ {:join, player()}
  end

  def list(room) do
    room <~ :list
  end

  def leave(room) do
    room <~ {:leave, player()}
  end

  def ready(room) do
    room <~ {:ready, player()}
  end
end
