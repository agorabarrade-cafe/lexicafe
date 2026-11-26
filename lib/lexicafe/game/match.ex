defmodule Lexicafe.Game.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matches" do
    field :code, :string
    field :mode, :string
    field :state, :map
    timestamps(type: :utc_datetime)
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [:code, :mode, :state])
    |> validate_required([:code, :mode, :state])
    |> unique_constraint(:code)
  end
end
