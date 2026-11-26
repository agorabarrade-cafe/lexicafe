defmodule Lexicafe.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :code, :string, null: false
      add :mode, :string, null: false
      add :state, :map, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:matches, [:code])
  end
end
