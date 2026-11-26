defmodule Lexicafe.Game.Server do
  @moduledoc "El GenServer serializa turnos y persiste cada cambio confirmado."
  use GenServer

  alias Lexicafe.{Repo, Games}
  alias Lexicafe.Game.{Engine, Match}
  alias LexicafeWeb.Presence

  def start_link(code) do
    GenServer.start_link(__MODULE__, code, name: {:via, Registry, {Lexicafe.GameRegistry, code}})
  end

  @impl true
  def init(code) do
    match = Repo.get_by!(Match, code: code)
    {:ok, %{id: match.id, code: code, game: match.state}}
  end

  @impl true
  def handle_call({:join, player_id}, _from, server) do
    case Engine.join(server.game, player_id) do
      {:ok, new_game, changed?} ->
        server = if changed?, do: persist(server, new_game), else: server
        {:reply, {:ok, Engine.public_view(server.game, player_id)}, server}
      {:error, reason} -> {:reply, {:error, reason}, server}
    end
  end

  def handle_call({:snapshot, player_id}, _from, server) do
    if Enum.any?(server.game["players"], &(&1["id"] == player_id)) do
      {:reply, {:ok, Engine.public_view(server.game, player_id)}, server}
    else
      {:reply, {:error, "No perteneces a la sala."}, server}
    end
  end

  def handle_call(:online, _from, server) do
    ids = Presence.list(Games.presence_topic(server.code))
    seats = Enum.map(server.game["players"], &(Map.has_key?(ids, &1["id"])))
    {:reply, seats, server}
  end

  def handle_call({:place, player_id, placements}, _from, server) do
    mutate(server, player_id, fn game -> Engine.place(game, player_id, placements) end)
  end

  def handle_call({:pass, player_id}, _from, server) do
    mutate(server, player_id, fn game -> Engine.pass(game, player_id) end)
  end

  def handle_call({:exchange, player_id, indices}, _from, server) do
    mutate(server, player_id, fn game -> Engine.exchange(game, player_id, indices) end)
  end

  defp mutate(server, player_id, action) do
    case action.(server.game) do
      {:ok, new_game} ->
        server = persist(server, new_game)
        {:reply, {:ok, Engine.public_view(server.game, player_id)}, server}
      {:error, reason} -> {:reply, {:error, reason}, server}
    end
  end

  defp persist(server, new_game) do
    server.id
    |> then(&Repo.get!(Match, &1))
    |> Ecto.Changeset.change(state: new_game)
    |> Repo.update!()

    Phoenix.PubSub.broadcast(Lexicafe.PubSub, Games.topic(server.code), :game_updated)
    %{server | game: new_game}
  end
end
