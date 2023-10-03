defmodule Werewolf.Game.Supervisor do
  use DynamicSupervisor
  alias Werewolf.Game

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(room_id) do
    DynamicSupervisor.start_child(__MODULE__, %{id: Game.State, start: {Game.State, :start_link, [room_id]}, restart: :transient})
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
