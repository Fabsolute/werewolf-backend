defmodule WerewolfWeb.AuthComponent do
  use WerewolfWeb, :live_component

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
        send(self(), {:authenticated, username})

        {
          :noreply,
          socket
          |> assign(authenticated: true)
        }
    end
  end
end
