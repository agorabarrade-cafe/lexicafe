defmodule Lexicafe.Game.TileBag do
  @moduledoc "Fichas y puntos de un juego original de palabras españolas."
  @quantities %{
    "A" => 12, "E" => 12, "O" => 9, "I" => 6, "U" => 5,
    "N" => 5, "R" => 5, "S" => 6, "L" => 4, "T" => 4,
    "D" => 4, "C" => 4, "M" => 3, "P" => 3, "B" => 2,
    "G" => 2, "V" => 2, "H" => 2, "F" => 1, "J" => 1,
    "Ñ" => 1, "Q" => 1, "X" => 1, "Z" => 1, "Y" => 1
  }
  @points %{
    "A" => 1, "E" => 1, "I" => 1, "O" => 1, "U" => 1,
    "N" => 1, "R" => 1, "S" => 1, "L" => 1, "T" => 1,
    "D" => 2, "G" => 2,
    "C" => 3, "M" => 3, "P" => 3, "B" => 3,
    "V" => 4, "H" => 4, "F" => 4, "Y" => 4,
    "Q" => 5, "J" => 8, "Ñ" => 8, "X" => 8, "Z" => 10
  }

  def new do
    @quantities
    |> Enum.flat_map(fn {letter, amount} -> List.duplicate(letter, amount) end)
    |> Enum.shuffle()
  end

  def points(letter), do: Map.fetch!(@points, letter)
  def draw(bag, amount) when amount >= 0, do: Enum.split(bag, amount)
end
