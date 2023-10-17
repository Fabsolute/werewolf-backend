defmodule Werewolf.Game.PlayerState do
  defstruct role: nil, ready: false

  def new(), do: %__MODULE__{}

  def ready(player) do
    Map.put(player, :ready, !player.ready)
  end

  def safe({player, info}) do
    %{player: player, ready: info.ready}
  end
end
