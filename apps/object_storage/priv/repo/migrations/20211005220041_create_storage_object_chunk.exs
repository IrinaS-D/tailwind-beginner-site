defmodule ObjectStorage.Repo.Migrations.CreateStorageObjectChunk do
  use Ecto.Migration

  def change do
    create table(:storage_object_chunks) do
      add :path, :string
      add :body, :binary
      add :part_number, :integer

      timestamps()
    end

    create unique_index(:storage_object_chunks, [:path, :part_number])
  end
end
