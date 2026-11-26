defmodule Lexicafe.Game.EngineTest do
  use ExUnit.Case, async: true
  alias Lexicafe.Game.Engine

  @bag ["C", "A", "F", "E", "S", "O", "L", "C", "A", "S", "A", "M", "I", "N", "P", "A", "N"]

  defp first_move do
    [%{"pos" => 58, "rack_index" => 0}, %{"pos" => 59, "rack_index" => 1},
     %{"pos" => 60, "rack_index" => 2}, %{"pos" => 61, "rack_index" => 3}]
  end

  test "solo: suma puntos, repone fichas y termina después de pases" do
    state = Engine.new("TEST01", "solo", "owner", bag: @bag)
    assert {:ok, played} = Engine.place(state, "owner", first_move())
    assert (played["players"] |> hd() |> Map.fetch!("score")) == 24
    assert length(hd(played["players"])["rack"]) == 7
    assert Enum.at(played["board"], 60)["letter"] == "F"
    assert {:ok, once} = Engine.pass(played, "owner")
    assert {:ok, twice} = Engine.pass(once, "owner")
    assert twice["status"] == "finished"
  end

  test "duelo: asigna letras distintas, turnos y nunca filtra atril contrario" do
    state = Engine.new("TEST02", "duo", "owner", bag: @bag)
    assert {:ok, joined, true} = Engine.join(state, "guest")
    assert joined["status"] == "playing"
    assert {:error, _} = Engine.place(joined, "guest", first_move())
    assert {:ok, played} = Engine.place(joined, "owner", first_move())
    assert played["turn"] == 1
    view = Engine.public_view(played, "owner")
    assert view.my_turn == false
    refute Map.has_key?(hd(view.players), "rack")
    assert length(view.rack) == 7
    assert {:ok, crossed} = Engine.place(played, "guest", [
      %{"pos" => 48, "rack_index" => 0},
      %{"pos" => 70, "rack_index" => 2},
      %{"pos" => 81, "rack_index" => 3}
    ])
    assert crossed["turn"] == 0
    assert crossed["last"]["words"] == ["CASA"]
  end

  test "rechaza usar una ficha dos veces o falsificar un índice" do
    state = Engine.new("TEST03", "solo", "owner", bag: @bag)
    cheat = [%{"pos" => 59, "rack_index" => 0}, %{"pos" => 60, "rack_index" => 0}]
    assert {:error, _} = Engine.place(state, "owner", cheat)
    assert {:error, _} = Engine.place(state, "owner", [%{"pos" => 500, "rack_index" => 0}])
  end

  test "una sala es idempotente para el mismo invitado y limitada a dos" do
    state = Engine.new("TEST04", "duo", "owner", bag: @bag)
    assert {:ok, joined, true} = Engine.join(state, "guest")
    assert {:ok, ^joined, false} = Engine.join(joined, "guest")
    assert {:error, "La sala está completa."} = Engine.join(joined, "intruder")
  end

  test "permite cambiar una ficha con bolsa disponible" do
    state = Engine.new("TEST05", "solo", "owner", bag: @bag)
    assert {:ok, next} = Engine.exchange(state, "owner", 1)
    assert length(hd(next["players"])["rack"]) == 7
    assert next["passes"] == 1
  end

  test "cambia varias letras seleccionadas en una sola acción, conservando el tamaño de la bolsa" do
    state = Engine.new("TEST06", "solo", "owner", bag: @bag)
    assert {:ok, next} = Engine.exchange(state, "owner", [0, 2, 5])
    assert length(hd(next["players"])["rack"]) == 7
    assert length(next["bag"]) == length(state["bag"])
    assert next["last"]["words"] == ["CAMBIÓ 3 FICHAS"]
    assert next["passes"] == 1
  end

  test "el cambio múltiple rechaza índices duplicados, vacíos o más que la bolsa" do
    state = Engine.new("TEST07", "solo", "owner", bag: @bag)
    assert {:error, _} = Engine.exchange(state, "owner", [])
    assert {:error, _} = Engine.exchange(state, "owner", [1, 1])
    assert {:error, _} = Engine.exchange(state, "owner", [0, 99])
    assert {:error, _} = Engine.exchange(state, "owner", [0, "2"])

    few_tiles = put_in(state["bag"], ["X"])
    assert {:error, _} = Engine.exchange(few_tiles, "owner", [0, 1])
  end
end
