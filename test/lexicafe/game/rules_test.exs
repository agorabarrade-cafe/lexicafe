defmodule Lexicafe.Game.RulesTest do
  use ExUnit.Case, async: true
  alias Lexicafe.Game.Rules

  defp tiles(pairs), do: Enum.map(pairs, fn {pos, letter} -> {pos, %{"letter" => letter}} end)
  defp empty, do: List.duplicate(nil, 121)

  test "primera palabra cruza el centro y usa bonos" do
    assert {:ok, result} = Rules.evaluate(empty(), tiles([{58, "C"}, {59, "A"}, {60, "F"}, {61, "E"}]))
    assert result.words == ["CAFE"]
    assert result.score == 24
    assert Enum.at(result.board, 60)["letter"] == "F"
  end

  test "no permite primera palabra sin cubrir centro" do
    assert {:error, msg} = Rules.evaluate(empty(), tiles([{35, "P"}, {36, "A"}, {37, "N"}]))
    assert msg =~ "central"
  end

  test "valida cruce usando letra existente" do
    {:ok, first} = Rules.evaluate(empty(), tiles([{58, "C"}, {59, "A"}, {60, "F"}, {61, "E"}]))
    assert {:ok, next} = Rules.evaluate(first.board, tiles([{48, "C"}, {70, "S"}, {81, "A"}]))
    assert next.words == ["CASA"]
    assert next.score > 0
  end

  test "rechaza palabras desconocidas y jugadas separadas" do
    assert {:error, msg} = Rules.evaluate(empty(), tiles([{59, "Z"}, {60, "Z"}, {61, "Z"}]))
    assert msg =~ "diccionario"
    assert {:error, msg2} = Rules.evaluate(empty(), tiles([{59, "C"}, {60, "A"}, {72, "F"}]))
    assert msg2 =~ "fila o columna"
  end

  test "rechaza huecos entre fichas" do
    assert {:error, msg} = Rules.evaluate(empty(), tiles([{58, "P"}, {60, "A"}]))
    assert msg =~ "huecos"
  end
end
