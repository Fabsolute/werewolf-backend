defmodule WerewolfWeb.LobbyComponent do
  use WerewolfWeb, :live_component
  alias Werewolf.Game

  def handle_event("ready", _unsigned_params, socket) do
    Game.ready(socket.assigns.room)
    {:noreply, socket}
  end
end
