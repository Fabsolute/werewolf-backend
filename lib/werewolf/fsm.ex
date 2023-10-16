defmodule Werewolf.FSM do
  defmodule State do
    defmacro __using__(list) do
      quote location: :keep, bind_quoted: [list: list] do
        if list == [] or Keyword.get(list, :change_state, false) do
          defp change_state(new_state) do
            GenServer.cast(self(), {:change_state, new_state})
          end
        end

        if list == [] or Keyword.get(list, :message, false) do
          defmacro room <<~ message do
            quote do
              GenServer.call(via(unquote(room)), {:user_message, unquote(message)})
            end
          end

          defmacro room <~ message do
            quote do
              GenServer.cast(via(unquote(room)), {:user_message, unquote(message)})
            end
          end
        end

        if list == [] or Keyword.get(list, :via, false) do
          defp via(room_id) do
            {:via, Registry, {Werewolf.Registry, {__MODULE__, room_id}}}
          end
        end

        if list == [] or Keyword.get(list, :ok, false) do
          defp ok(new_game_state) do
            {:noreply, new_game_state}
          end
        end

        if list == [] or Keyword.get(list, :stop, false) do
          defp stop(response, reason \\ :shutdown) do
            {:stop, reason, response}
          end
        end
      end
    end
  end

  defmacro __using__(_opts) do
    quote location: :keep do
      use Werewolf.FSM.State, via: true, message: true
      use GenServer

      def start_link(room_id) do
        GenServer.start_link(__MODULE__, room_id, name: via(room_id))
      end

      @impl true
      def init(room_id) do
        {:ok, game_init(room_id)}
      end

      @impl true
      def handle_cast({:change_state, new_state}, {_room_state, game_state}) do
        {:noreply, {new_state, game_state}}
      end

      @impl true
      def handle_cast({:user_message, message}, {room_state, game_state}) do
        case apply(room_state, :handle_cast, [message, game_state]) do
          {:noreply, new_game_state} ->
            {:noreply, {room_state, new_game_state}}

          {:stop, reason, new_game_state} ->
            {:stop, reason, {room_state, new_game_state}}
        end
      end

      @impl true
      def handle_call({:user_message, message}, from, {room_state, game_state}) do
        case apply(room_state, :handle_call, [message, from, game_state]) do
          {:noreply, new_game_state} ->
            {:noreply, {room_state, new_game_state}}

          {:reply, response, new_game_state} ->
            {:reply, response, {room_state, new_game_state}}

          {:stop, reason, new_game_state} ->
            {:stop, reason, {room_state, new_game_state}}
        end
      end
    end
  end
end
