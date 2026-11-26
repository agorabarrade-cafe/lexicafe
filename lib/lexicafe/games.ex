defmodule Lexicafe.Games do
  @moduledoc "Acceso a partidas de Lexicafé. Un GenServer autoritativo por sala."
  alias Lexicafe.{Repo}
  alias Lexicafe.Game.{Engine, Match, Server}

  def create(mode, player_id) when mode in ["solo", "duo"] do
    Enum.reduce_while(1..8, {:error, "No se pudo crear la sala."}, fn _, _ ->
      code = random_code()
      attrs = %{code: code, mode: mode, state: Engine.new(code, mode, player_id)}
      case %Match{} |> Match.changeset(attrs) |> Repo.insert() do
        {:ok, _} -> {:halt, {:ok, code}}
        {:error, _} -> {:cont, {:error, "No se pudo crear la sala."}}
      end
    end)
  end

  def create(_mode, _player_id), do: {:error, "Modo de juego inválido."}

  def exists?(code), do: Repo.exists?(from_match(code))

  def join(code, player_id), do: call(code, {:join, player_id})
  def snapshot(code, player_id), do: call(code, {:snapshot, player_id})
  def online(code), do: call(code, :online)
  def place(code, player_id, placements), do: call(code, {:place, player_id, placements})
  def pass(code, player_id), do: call(code, {:pass, player_id})
  def exchange(code, player_id, indices), do: call(code, {:exchange, player_id, indices})

  def topic(code), do: "lexicafe:#{code}"
  def presence_topic(code), do: "lexicafe:presence:#{code}"

  defp from_match(code) do
    import Ecto.Query
    from(m in Match, where: m.code == ^code)
  end

  defp call(code, request) do
    with {:ok, pid} <- ensure_server(code) do
      GenServer.call(pid, request, 10_000)
    end
  end

  defp ensure_server(code) do
    case Registry.lookup(Lexicafe.GameRegistry, code) do
      [{pid, _}] -> {:ok, pid}
      [] ->
        if exists?(code) do
          case DynamicSupervisor.start_child(Lexicafe.GameSupervisor, {Server, code}) do
            {:ok, pid} -> {:ok, pid}
            {:error, {:already_started, pid}} -> {:ok, pid}
            {:error, {:shutdown, {:failed_to_start_child, _, {:already_started, pid}}}} -> {:ok, pid}
            {:error, reason} -> {:error, inspect(reason)}
          end
        else
          {:error, "No existe esa sala."}
        end
    end
  end

  defp random_code do
    alphabet = String.graphemes("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    for _ <- 1..6, into: "", do: Enum.random(alphabet)
  end
end
