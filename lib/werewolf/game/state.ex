defmodule Werewolf.Game.State do
  defstruct id: nil, leader: nil, room_state: :lobby, players: [], day: 0, is_night: false

  use Werewolf.FSM
  alias Werewolf.Game.Supervisor

  def game_init(room_id) do
    %__MODULE__{id: room_id}
  end

  def handle_message(:lobby, {:join, new_player}, state) do
    leader = if state.leader == nil, do: new_player, else: state.leader

    ok(
      state
      |> Map.put(:players, [new_player | state.players])
      |> Map.put(:leader, leader)
    )
  end

  def handle_message(:lobby, {:leave, player}, state) do
    new_player_list = Enum.reject(state.players, fn p -> p == player end)

    new_state =
      state
      |> Map.put(:players, new_player_list)

    if new_player_list == [] do
      stop(new_state)
    else
      ok(new_state)
    end
  end

  def handle_message(:lobby, :list, state) do
    state.players |> IO.inspect(label: :players)
    change_state(:game)
    ok(state)
  end

  def handle_message(:game, :list, state) do
    IO.inspect("Hey", label: :game)
    change_state(:lobby)
    ok(state)
  end

  def join(room_id) do
    # todo i hate this code it shouldn't be here!11
    Supervisor.start_child(room_id) |> IO.inspect(label: :join)
    send_message(room_id, {:join, self()})
  end

  def list(room_id) do
    send_message(room_id, :list)
  end

  def leave(room_id) do
    send_message(room_id, {:leave, self()})
  end
end
