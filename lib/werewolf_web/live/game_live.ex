defmodule WerewolfWeb.GameLive do
  use WerewolfWeb, :live_view
  alias Werewolf.Game

  def mount(params, _payload, socket) do
    default_values = [room: nil, authenticated: false, state: nil, in_game: false]

    case Map.fetch(params, "room_id") do
      {:ok, room_id} ->
        {
          :ok,
          socket
          |> assign(Keyword.put(default_values, :room, {:room, room_id}))
        }

      _ ->
        {:ok, socket |> assign(default_values)}
    end
  end

  def handle_params(params, _uri, socket) do
    {:ok, socket} = mount(params, nil, socket)
    {:noreply, socket}
  end

  def handle_info({:state_changed, new_state}, socket) do
    {:noreply, socket |> assign(state: new_state) |> IO.inspect(label: :state_changed)}
  end

  def handle_info({:authenticated, username}, socket) do
    Game.join(socket.assigns.room, username)

    {:noreply, socket |> assign(authenticated: true, username: username)}
  end

  def handle_info({:counter, n}, socket) do
    {:noreply, socket |> assign(:state, Map.put(socket.assigns.state, :counter, n))}
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
