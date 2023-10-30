defmodule Werewolf.Util.Timer do
  use GenServer

  def start!(message, total, args \\ []) do
    {:ok, timer} =
      Werewolf.Supervisor.start_child(%{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [{self(), message, total, args}]}
      })

    timer
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init({pid, message, total, args}) do
    period = Keyword.get(args, :period, 1000)
    timer = Process.send_after(self(), :heartbeat, period)

    state =
      %{
        pid: pid,
        wrapper: Keyword.get(args, :wrapper, & &1),
        message: message,
        total: total,
        period: period,
        state: :counting,
        timer: timer
      }
      |> notify

    {:ok, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    if state.timer != nil do
      Process.cancel_timer(state.timer)
    end

    state = state |> Map.put(:state, :stopped) |> notify

    {:stop, :shutdown, state}
  end

  @impl true
  def handle_info(:heartbeat, %{state: :counting} = state) do
    state = state |> Map.put(:total, state.total - state.period)

    state =
      if state.total <= 0 do
        Map.put(state, :state, :completed)
      else
        state
      end

    notify(state)

    state =
      Map.put(
        state,
        :timer,
        if state.state == :counting do
          Process.send_after(self(), :heartbeat, state.period)
        end
      )

    {:noreply, state}
  end

  defp notify(state) do
    case state.state do
      :counting ->
        send(
          state.pid,
          state.wrapper.(
            {:timer_message, self(),
             [
               state: :counting,
               message: state.message,
               remainder: state.total,
               period: state.period
             ]}
          )
        )

      :completed ->
        send(
          state.pid,
          state.wrapper.({:timer_message, self(), [state: :completed, message: state.message]})
        )

      :stopped ->
        send(
          state.pid,
          state.wrapper.(
            {:timer_message, self(),
             [
               state: :stopped,
               message: state.message,
               remainder: state.total,
               period: state.period
             ]}
          )
        )
    end

    state
  end
end
