defmodule Werewolf.Game.PlayerState do
  defstruct username: nil, role: nil, ready: false

  def new(username), do: %__MODULE__{username: username}

  def ready(player) do
    Map.put(player, :ready, !player.ready)
  end

  def safe({player, info}) do
    %{player: player, username: info.username, ready: info.ready}
  end
end
