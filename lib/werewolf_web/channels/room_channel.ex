defmodule WerewolfWeb.RoomChannel do
  use WerewolfWeb, :channel
  alias WerewolfWeb.Presence
  alias Werewolf.Game.State, as: Game

  intercept ["presence_diff"]

  @impl true
  def join("room:" <> room_id, %{"username" => username} = payload, socket) do
    case check_authorization(socket, payload) do
      :success ->
        send(self(), :after_join)

        {
          :ok,
          socket
          |> assign(:room_id, room_id)
          |> assign(:username, username)
        }

      :unauthorized ->
        {:error, %{reason: "unauthorized"}}

      :username_exists ->
        {:error, %{reason: "username exists"}}
    end
  end

  @impl true
  def handle_in("ready", %{}, socket) do
    Game.ready(socket.assigns.room_id)
    {:noreply, socket}
  end

  # @impl true
  # def handle_in("ping", payload, socket) do
  #   Game.list(socket.assigns.room_id)
  #
  #   {:reply,
  #    {:ok,
  #     %{
  #       hey: payload,
  #       room_id: socket.assigns.room_id,
  #       username: socket.assigns.username
  #     }}, socket |> assign(:ping, true)}
  # end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", %{payload: payload, username: socket.assigns.username})
    {:noreply, socket}
  end

  @impl true
  def handle_out("presence_diff", %{joins: joins, leaves: leaves}, socket) do
    push(socket, "presence_diff", %{
      joins: Map.keys(joins),
      leaves: Map.keys(leaves)
    })

    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns.username, %{})
    push(socket, "presence_state", %{users: Presence.list(socket) |> Map.keys()})

    Game.join(socket.assigns.room_id)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    Game.leave(socket.assigns.room_id)
    {:stop, :shutdown, socket}
  end

  # Add authorization logic here as required.
  defp check_authorization(socket, %{"username" => username}) do
    if Presence.list(socket) |> Map.keys() |> Enum.any?(&(&1 == username)) do
      :username_exists
    else
      :success
    end
  end
end
