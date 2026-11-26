defmodule Lexicafe.Game.DictionaryTest do
  use ExUnit.Case, async: true
  alias Lexicafe.Game.Dictionary

  test "acepta café sin tilde e identifica la Ñ" do
    assert Dictionary.valid?("café")
    assert Dictionary.valid?("niño")
    refute Dictionary.normalized("niño") == Dictionary.normalized("nino")
    refute Dictionary.valid?("CAXWQXZ")
    assert Dictionary.size() > 1000
    if Dictionary.source() == :extended, do: assert(Dictionary.size() > 10000)
  end
end
