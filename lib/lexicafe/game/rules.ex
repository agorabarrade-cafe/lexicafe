defmodule Lexicafe.Game.Rules do
  @moduledoc """
  Valida una jugada completa de palabras cruzadas en un tablero 11×11.
  Únicamente se forman palabras de dos o más letras y los bonos solo se
  aplican al colocar letras nuevas.
  """
  alias Lexicafe.Game.{Dictionary, TileBag}

  @size 11
  @center 60
  @triple_word [{0, 0}, {0, 10}, {10, 0}, {10, 10}]
  @double_word [{1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9},
                {1, 9}, {2, 8}, {3, 7}, {4, 6}, {6, 4}, {7, 3}, {8, 2}, {9, 1}]
  @triple_letter [{1, 5}, {5, 1}, {5, 9}, {9, 5}]
  @double_letter [{0, 3}, {0, 7}, {3, 0}, {3, 5}, {3, 10},
                  {5, 3}, {5, 7}, {7, 0}, {7, 5}, {7, 10}, {10, 3}, {10, 7}]

  def size, do: @size
  def center, do: @center

  def bonus(pos) when is_integer(pos) and pos >= 0 and pos < 121 do
    coordinates = {div(pos, @size), rem(pos, @size)}
    cond do
      coordinates in @triple_word -> "TW"
      coordinates in @double_word -> "DW"
      coordinates in @triple_letter -> "TL"
      coordinates in @double_letter -> "DL"
      true -> nil
    end
  end

  @doc "Returns the new board, formed words, and total earned points."
  def evaluate(board, placements) when is_list(board) and is_list(placements) do
    positions = Enum.map(placements, fn {pos, _tile} -> pos end)
    valid_positions = positions != [] and
      Enum.all?(positions, &valid_pos?/1) and
      length(Enum.uniq(positions)) == length(positions)

    cond do
      length(board) != 121 -> {:error, "El tablero no tiene 11×11 casillas."}
      not valid_positions -> {:error, "Posiciones de fichas inválidas."}
      Enum.any?(positions, &(Enum.at(board, &1) != nil)) ->
        {:error, "Una de las casillas ya está ocupada."}
      true -> check_words(board, placements, positions)
    end
  end

  defp check_words(board, placements, positions) do
    after_board = Enum.reduce(placements, board, fn {pos, tile}, acc ->
      List.replace_at(acc, pos, tile)
    end)

    with {:ok, orientation} <- orientation(positions),
         :ok <- contiguous(after_board, positions, orientation),
         :ok <- connected(board, positions),
         {:ok, words} <- extract_words(after_board, positions, orientation),
         :ok <- valid_words(words, after_board) do
      placed = MapSet.new(positions)
      points = Enum.reduce(words, 0, fn word, acc ->
        acc + score_word(word, after_board, placed)
      end) + if(length(positions) == 7, do: 35, else: 0)

      labels = Enum.map(words, fn word -> word_text(word, after_board) end)
      {:ok, %{board: after_board, words: labels, score: points}}
    end
  end

  defp valid_pos?(pos), do: is_integer(pos) and pos in 0..120

  defp orientation([_]), do: {:ok, :single}
  defp orientation(positions) do
    rows = Enum.map(positions, &div(&1, @size)) |> Enum.uniq()
    cols = Enum.map(positions, &rem(&1, @size)) |> Enum.uniq()
    cond do
      length(rows) == 1 -> {:ok, :horizontal}
      length(cols) == 1 -> {:ok, :vertical}
      true -> {:error, "Coloca las letras nuevas en una sola fila o columna."}
    end
  end

  defp contiguous(_board, _positions, :single), do: :ok
  defp contiguous(board, positions, orientation) do
    {low, high} = Enum.min_max(positions)
    step = if orientation == :horizontal, do: 1, else: @size
    if Enum.all?(Enum.take_every(low..high, step), &(Enum.at(board, &1) != nil)) do
      :ok
    else
      {:error, "No puedes dejar huecos entre las letras de la palabra."}
    end
  end

  defp connected(board, positions) do
    old_board_empty? = Enum.all?(board, &is_nil/1)
    cond do
      old_board_empty? and @center not in positions ->
        {:error, "La primera palabra debe cubrir la casilla central ★."}
      old_board_empty? -> :ok
      Enum.any?(positions, fn pos ->
        Enum.any?(neighbors(pos), &(Enum.at(board, &1) != nil))
      end) -> :ok
      true -> {:error, "La jugada debe conectar con una letra existente."}
    end
  end

  defp neighbors(pos) do
    row = div(pos, @size)
    col = rem(pos, @size)
    [{row - 1, col}, {row + 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(fn {r, c} -> r in 0..10 and c in 0..10 end)
    |> Enum.map(fn {r, c} -> r * @size + c end)
  end

  defp extract_words(board, positions, :single) do
    [pos] = positions
    words = [:horizontal, :vertical]
      |> Enum.map(&word_positions(board, pos, &1))
      |> Enum.filter(&(length(&1) > 1))
      |> Enum.uniq()
    if words == [], do: {:error, "Debes formar una palabra de al menos dos letras."}, else: {:ok, words}
  end

  defp extract_words(board, positions, direction) do
    primary = word_positions(board, hd(positions), direction)
    other = if direction == :horizontal, do: :vertical, else: :horizontal
    crosses = Enum.map(positions, &word_positions(board, &1, other))
    words = [primary | crosses] |> Enum.filter(&(length(&1) > 1)) |> Enum.uniq()
    if words == [], do: {:error, "Debes formar una palabra de al menos dos letras."}, else: {:ok, words}
  end

  defp word_positions(board, pos, direction) do
    {row, col} = {div(pos, @size), rem(pos, @size)}
    {dr, dc} = if direction == :horizontal, do: {0, 1}, else: {1, 0}
    before = walk(board, row - dr, col - dc, -dr, -dc, []) |> Enum.reverse()
    after_positions = walk(board, row + dr, col + dc, dr, dc, [])
    before ++ [pos] ++ after_positions
  end

  defp walk(board, row, col, dr, dc, acc) when row in 0..10 and col in 0..10 do
    pos = row * @size + col
    if Enum.at(board, pos) do
      walk(board, row + dr, col + dc, dr, dc, [pos | acc])
    else
      Enum.reverse(acc)
    end
  end
  defp walk(_board, _row, _col, _dr, _dc, acc), do: Enum.reverse(acc)

  defp word_text(word, board), do: Enum.map_join(word, "", &(Enum.at(board, &1)["letter"]))

  defp valid_words(words, board) do
    invalid = words
      |> Enum.map(&word_text(&1, board))
      |> Enum.reject(&Dictionary.valid?/1)

    if invalid == [], do: :ok,
      else: {:error, "Palabra no reconocida por el diccionario: #{Enum.join(invalid, ", ")}."}
  end

  defp score_word(positions, board, placed_positions) do
    {letters, multiplier} = Enum.reduce(positions, {0, 1}, fn pos, {sum, wmult} ->
      tile = Enum.at(board, pos)
      value = TileBag.points(tile["letter"])
      if MapSet.member?(placed_positions, pos) do
        {sum + value * letter_multiplier(pos), wmult * word_multiplier(pos)}
      else
        {sum + value, wmult}
      end
    end)
    letters * multiplier
  end

  defp letter_multiplier(pos) do
    case bonus(pos) do
      "DL" -> 2
      "TL" -> 3
      _ -> 1
    end
  end

  defp word_multiplier(pos) do
    case bonus(pos) do
      "DW" -> 2
      "TW" -> 3
      _ -> 1
    end
  end
end
