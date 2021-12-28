defmodule Legendary.ObjectStorage.ObjectChunk do
  @moduledoc """
  One chunk of a chunked upload.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "storage_object_chunks" do
    field :body, :binary
    field :part_number, :integer
    field :path, :string

    timestamps()
  end

  @doc false
  def changeset(object_chunk, attrs) do
    object_chunk
    |> cast(attrs, [:path, :body, :part_number])
    |> validate_required([:path, :body, :part_number])
  end

  def etag(chunk) do
    key = "#{chunk.path}:#{chunk.part_number}:#{chunk.inserted_at}"

    Base.encode16(:crypto.hash(:md5 , key))
  end
end
