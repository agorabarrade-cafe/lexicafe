defmodule Lexicafe.Game.Engine do
  @moduledoc """
  Motor puro de Lexicafé. El servidor confía solo en sus fichas y no en letras
  enviadas por el navegador. Todas las mutaciones son serializadas por un GenServer.
  """
  alias Lexicafe.Game.{Rules, TileBag}

  def new(code, mode, owner, opts \\ []) when mode in ["solo", "duo"] do
    bag = Keyword.get(opts, :bag, TileBag.new())
    {rack, remaining} = TileBag.draw(bag, 7)
    %{
      "code" => code,
      "mode" => mode,
      "board" => List.duplicate(nil, 121),
      "bag" => remaining,
      "players" => [%{"id" => owner, "name" => "Jugador 1", "rack" => rack, "score" => 0}],
      "turn" => 0,
      "status" => if(mode == "solo", do: "playing", else: "waiting"),
      "passes" => 0,
      "version" => 0,
      "last" => nil,
      "history" => []
    }
  end

  def join(state, player_id) do
    players = state["players"]
    cond do
      Enum.any?(players, &(&1["id"] == player_id)) -> {:ok, state, false}
      state["mode"] == "solo" -> {:error, "Esta es una partida individual."}
      length(players) >= 2 -> {:error, "La sala está completa."}
      state["status"] == "finished" -> {:error, "La partida ya terminó."}
      true ->
        {rack, bag} = TileBag.draw(state["bag"], 7)
        new_player = %{"id" => player_id, "name" => "Jugador 2", "rack" => rack, "score" => 0}
        updated = state
          |> Map.put("players", players ++ [new_player])
          |> Map.put("bag", bag)
          |> Map.put("status", "playing")
          |> bump_version()
        {:ok, updated, true}
    end
  end

  def place(state, player_id, placements) when is_list(placements) do
    with {:ok, index, player} <- active_player(state, player_id),
         {:ok, letters} <- resolve_rack(placements, player["rack"], state["board"]),
         {:ok, result} <- Rules.evaluate(state["board"], letters) do
      selected = placements |> Enum.map(& &1["rack_index"]) |> MapSet.new()
      keep = player["rack"] |> Enum.with_index() |> Enum.reject(fn {_letter, i} -> MapSet.member?(selected, i) end) |> Enum.map(&elem(&1, 0))
      {drawn, bag} = TileBag.draw(state["bag"], 7 - length(keep))
      updated_player = player
        |> Map.put("rack", keep ++ drawn)
        |> Map.update!("score", &(&1 + result.score))
      players = List.replace_at(state["players"], index, updated_player)
      last = %{"by" => player_id, "words" => result.words, "points" => result.score}
      finished = bag == [] and updated_player["rack"] == []
      updated = state
        |> Map.put("board", result.board)
        |> Map.put("bag", bag)
        |> Map.put("players", players)
        |> Map.put("last", last)
        |> Map.put("passes", 0)
        |> Map.put("turn", next_turn(state))
        |> Map.put("status", if(finished, do: "finished", else: "playing"))
        |> Map.update!("history", fn history -> [last | history] |> Enum.take(15) end)
        |> bump_version()
      {:ok, updated}
    end
  end
  def place(_state, _player_id, _placements), do: {:error, "La jugada es inválida."}

  def pass(state, player_id) do
    with {:ok, _idx, _player} <- active_player(state, player_id) do
      count = state["passes"] + 1
      limit = if state["mode"] == "solo", do: 2, else: 4
      updated = state
        |> Map.put("passes", count)
        |> Map.put("turn", next_turn(state))
        |> Map.put("status", if(count >= limit, do: "finished", else: "playing"))
        |> Map.put("last", %{"by" => player_id, "words" => ["PASÓ"], "points" => 0})
        |> bump_version()
      {:ok, updated}
    end
  end

  def exchange(state, player_id, rack_index) when is_integer(rack_index),
    do: exchange(state, player_id, [rack_index])

  def exchange(state, player_id, rack_indices) when is_list(rack_indices) do
    with {:ok, index, player} <- active_player(state, player_id),
         :ok <- validate_exchange(state, player, rack_indices) do
      # Take replacement letters before returning the originals to the bag.
      {new_letters, remaining_bag} = TileBag.draw(state["bag"], length(rack_indices))
      replacements = Enum.zip(rack_indices, new_letters) |> Map.new()

      old_letters = Enum.map(rack_indices, &Enum.at(player["rack"], &1))
      rack = player["rack"]
        |> Enum.with_index()
        |> Enum.map(fn {letter, i} -> Map.get(replacements, i, letter) end)
      updated_player = Map.put(player, "rack", rack)
      count = length(rack_indices)
      limit = if state["mode"] == "solo", do: 2, else: 4
      updated = state
        |> Map.put("players", List.replace_at(state["players"], index, updated_player))
        |> Map.put("bag", Enum.shuffle(old_letters ++ remaining_bag))
        |> Map.put("passes", state["passes"] + 1)
        |> Map.put("status", if(state["passes"] + 1 >= limit, do: "finished", else: "playing"))
        |> Map.put("turn", next_turn(state))
        |> Map.put("last", %{"by" => player_id, "words" => ["CAMBIÓ #{count} #{if count == 1, do: "FICHA", else: "FICHAS"}"], "points" => 0})
        |> bump_version()
      {:ok, updated}
    else
      {:error, _} = error -> error
    end
  end
  def exchange(_state, _player_id, _indices), do: {:error, "Selecciona letras válidas para cambiar."}

  defp validate_exchange(state, player, indices) do
    cond do
      indices == [] ->
        {:error, "Selecciona al menos una letra para cambiar."}
      length(Enum.uniq(indices)) != length(indices) ->
        {:error, "No puedes cambiar dos veces la misma ficha."}
      not Enum.all?(indices, &(is_integer(&1) and &1 >= 0 and &1 < length(player["rack"]))) ->
        {:error, "Selecciona letras válidas para cambiar."}
      length(state["bag"]) < length(indices) ->
        {:error, "No quedan suficientes fichas en la bolsa para realizar el cambio."}
      true -> :ok
    end
  end

  def public_view(state, player_id) do
    player = Enum.find(state["players"], &(&1["id"] == player_id))
    current = Enum.at(state["players"], state["turn"])
    %{
      code: state["code"],
      mode: state["mode"],
      board: state["board"],
      rack: if(player, do: player["rack"], else: []),
      players: Enum.with_index(state["players"]) |> Enum.map(fn {p, seat} -> %{seat: seat, name: p["name"], score: p["score"], me: p["id"] == player_id} end),
      status: state["status"],
      my_turn: state["status"] == "playing" and current != nil and current["id"] == player_id,
      active_seat: state["turn"],
      last: state["last"],
      bag_count: length(state["bag"]),
      version: state["version"]
    }
  end

  defp active_player(state, player_id) do
    players = state["players"]
    index = Enum.find_index(players, &(&1["id"] == player_id))
    cond do
      state["status"] == "waiting" -> {:error, "Espera a que se una otra persona."}
      state["status"] == "finished" -> {:error, "La partida ya terminó."}
      is_nil(index) -> {:error, "No perteneces a esta partida."}
      state["turn"] != index -> {:error, "Todavía no es tu turno."}
      true -> {:ok, index, Enum.at(players, index)}
    end
  end

  defp resolve_rack(placements, rack, board) do
    positions = Enum.map(placements, &Map.get(&1, "pos"))
    indexes = Enum.map(placements, &Map.get(&1, "rack_index"))
    valid? = placements != [] and length(placements) <= 7 and
      Enum.all?(positions, &(is_integer(&1) and &1 in 0..120)) and
      Enum.all?(indexes, &(is_integer(&1) and &1 >= 0 and &1 < length(rack))) and
      length(Enum.uniq(positions)) == length(positions) and
      length(Enum.uniq(indexes)) == length(indexes) and
      Enum.all?(positions, &(Enum.at(board, &1) == nil))
    if valid? do
      {:ok, Enum.map(placements, fn %{"pos" => pos, "rack_index" => index} ->
        {pos, %{"letter" => Enum.at(rack, index)}}
      end)}
    else
      {:error, "Selecciona letras distintas y casillas vacías."}
    end
  end

  defp next_turn(state), do: if(state["mode"] == "solo", do: 0, else: 1 - state["turn"])
  defp bump_version(state), do: Map.update!(state, "version", &(&1 + 1))
end
