defmodule Werewolf do
  @moduledoc """
  Werewolf keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Werewolf.Game.PlayerState

  def fun do
    quote do
      defp player() do
        {:player, self()}
      end

      defp via(room_id) do
        {:via, Registry, {Werewolf.Registry, {__MODULE__, room_id}}}
      end

      defmacro room <<~ message do
        quote bind_quoted: [room: room, message: message] do
          pid = self()

          case room do
            ^pid ->
              GenServer.call(pid, {:user_message, message})

            {:room, room_id} ->
              GenServer.call(via(room_id), {:user_message, message})

            {:player, player} ->
              send(player, message)
          end
        end
      end

      defmacro room <~ message do
        quote bind_quoted: [room: room, message: message] do
          pid = self()

          case room do
            ^pid ->
              GenServer.cast(pid, {:user_message, message})

            {:room, room_id} ->
              GenServer.cast(via(room_id), {:user_message, message})

            {:player, player} ->
              send(player, message)
          end
        end
      end
    end
  end

  def state do
    quote do
      use Werewolf, :fun
      alias Werewolf.Game.PlayerState

      defp safe(state, player) do
        %{
          day: state.day,
          is_night: state.is_night,
          leader: state.players[state.leader] |> PlayerState.safe(state.leader),
          players: state.players |> Map.to_list() |> Enum.map(&PlayerState.safe/1),
          you: state.players[player] |> PlayerState.safe(player)
        }
      end

      defp delay(message, delay) do
        Process.send_after(self(), {:user_message, message}, delay)
      end

      defp send_all(state, fun) do
        each_player(state, &(&1 <~ fun.(&1)))
      end

      defp each_player(state, fun) do
        state.players
        |> Map.keys()
        |> Enum.each(fun)
      end

      defp change_state(new_state) do
        GenServer.cast(self(), {:change_state, new_state})
      end

      defp ok(new_game_state) do
        {:noreply, new_game_state}
      end

      defp stop(response, reason \\ :shutdown) do
        {:stop, reason, response}
      end
    end
  end

  def fsm do
    quote do
      use Werewolf, :fun
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

      @impl true
      def handle_info({:user_message, message}, {room_state, game_state}) do
        case apply(room_state, :handle_info, [message, game_state]) do
          {:noreply, new_game_state} ->
            {:noreply, {room_state, new_game_state}}

          {:stop, reason, new_game_state} ->
            {:stop, reason, {room_state, new_game_state}}
        end
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
