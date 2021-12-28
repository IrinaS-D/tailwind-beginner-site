defmodule ObjectStorage.Repo.Migrations.CreateStorageObjects do
  use Ecto.Migration

  def change do
    create table(:storage_objects) do
      add :path, :string
      add :body, :binary
      add :acl, :string

      timestamps()
    end

    create unique_index(:storage_objects, :path)
  end
end
