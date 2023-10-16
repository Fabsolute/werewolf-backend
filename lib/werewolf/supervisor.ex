defmodule Werewolf.Supervisor do
  use DynamicSupervisor
  alias Werewolf.Game

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def ensure_child_started(room_id) do
    if Registry.lookup(Werewolf.Registry, room_id) == [] do
      DynamicSupervisor.start_child(__MODULE__, %{
        id: Game,
        start: {Game, :start_link, [room_id]},
        restart: :transient
      })
    end

    :ok
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
