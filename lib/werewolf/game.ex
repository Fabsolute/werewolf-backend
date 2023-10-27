defmodule Werewolf.Game do
  defstruct id: nil, leader: nil, players: %{}, day: 0, is_night: false, counter: nil

  use Werewolf, :fsm
  alias Werewolf.Game.PlayerState

  def game_init(room_id) do
    {Werewolf.Game.Lobby, %__MODULE__{id: room_id}}
  end

  def join({:room, room_id} = room, username) do
    Werewolf.Supervisor.ensure_child_started(room_id)

    room <~ {:join, player(), username}
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

  def handle_join(state, player, username) do
    leader = if state.leader == nil, do: player, else: state.leader

    broadcast(
      state
      |> Map.put(:players, Map.put(state.players, player, PlayerState.new(username)))
      |> Map.put(:leader, leader)
    )
  end

  def handle_leave(state, player) do
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
end
