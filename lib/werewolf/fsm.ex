defmodule Werewolf.FSM do
  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer

      def start_link(room_id) do
        GenServer.start_link(__MODULE__, {:lobby, room_id}, name: via(room_id))
      end

      @impl true
      def init({room_state, room_id}) do
        {:ok, {room_state, game_init(room_id)}}
      end

      @impl true
      def handle_cast({:change_state, new_state}, {_room_state, game_state}) do
        {:noreply, {new_state, game_state}}
      end

      @impl true
      def handle_cast({:user_message, pid, message}, {room_state, game_state}) do
        case apply(__MODULE__, :handle_message, [room_state, pid, message, game_state]) do
          {:ok, response} ->
            {:noreply, {room_state, response}}

          {:stop, response} ->
            {:stop, :shutdown, {room_state, response}}
        end
      end

      defp change_state(new_state) do
        GenServer.cast(self(), {:change_state, new_state})
      end

      defmacro room <~ message do
        quote do
          GenServer.cast(via(unquote(room)), {:user_message, self(), unquote(message)})
        end
      end

      defp via(room_id) do
        {:via, Registry, {Werewolf.Registry, {__MODULE__, room_id}}}
      end

      defp ok(response) do
        {:ok, response}
      end

      defp stop(response) do
        {:stop, response}
      end
    end
  end
end
