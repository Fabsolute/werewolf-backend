defmodule Werewolf.Game.State do
  defstruct id: nil, leader: nil, room_state: :lobby, players: %{}, day: 0, is_night: false

  use Werewolf.FSM
  alias Werewolf.Game.Supervisor
  alias Werewolf.Game.PlayerState

  def game_init(room_id) do
    %__MODULE__{id: room_id}
  end

  def handle_message(:lobby, from, :join, state) do
    leader = if state.leader == nil, do: from, else: state.leader

    ok(
      state
      |> Map.put(:players, Map.put(state.players, from, PlayerState.new()))
      |> Map.put(:leader, leader)
    )
  end

  def handle_message(:lobby, from, :ready, state) do
    new_state =
      state
      |> Map.put(:players, Map.update!(state.players, from, &PlayerState.ready/1))

    IO.inspect(new_state, label: :new_state_after_ready)
    # todo broadcast the updates!
    ok(new_state)
  end

  def handle_message(:lobby, from, :leave, state) do
    new_player_list = Map.delete(state.players, from)

    new_state =
      state
      |> Map.put(:players, new_player_list)

    if new_player_list == %{} do
      stop(new_state)
    else
      ok(new_state)
    end
  end

  def handle_message(:lobby, _from, :list, state) do
    state.players |> IO.inspect(label: :players)
    change_state(:game)
    ok(state)
  end

  def handle_message(:game, _from, :list, state) do
    IO.inspect("Hey", label: :game)
    change_state(:lobby)
    ok(state)
  end

  def join(room) do
    Supervisor.ensure_child_started(room)

    room <~ :join
  end

  def list(room) do
    room <~ :list
  end

  def leave(room) do
    room <~ :leave
  end

  def ready(room) do
    room <~ :ready
  end
end
