defmodule WerewolfWeb.GameLive do
  use WerewolfWeb, :live_view
  alias Werewolf.Game

  def mount(params, _payload, socket) do
    case Map.fetch(params, "room_id") do
      {:ok, room_id} ->
        {
          :ok,
          socket
          |> assign(room: {:room, room_id}, authenticated: false, state: nil)
        }

      _ ->
        {:ok, socket |> assign(room: nil)}
    end
  end

  def handle_params(params, _uri, socket) do
    {:ok, socket} = mount(params, nil, socket)
    {:noreply, socket}
  end

  def handle_event("join", %{"name" => room_name}, socket) do
    case String.trim(room_name) do
      "" ->
        {:noreply, socket |> put_flash(:error, "enter a valid room name")}

      room_name ->
        {:noreply, socket |> push_patch(to: "/#{room_name}")}
    end
  end

  def handle_event("login", %{"username" => username}, socket) do
    case String.trim(username) do
      "" ->
        {:noreply, socket |> put_flash(:error, "enter a valid username name")}

      username ->
        Game.join(socket.assigns.room, username)

        {
          :noreply,
          socket
          |> assign(username: username, authenticated: true)
        }
    end
  end

  def handle_info({:state_changed, new_state}, socket) do
    {:noreply, socket |> assign(state: new_state)}
  end

  def terminate(_reason, socket) do
    case socket.assigns.room do
      nil ->
        :ok

      room ->
        Game.leave(room)
    end

    {:stop, :shutdown, socket}
  end
end
