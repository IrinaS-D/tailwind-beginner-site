defmodule Legendary.ObjectStorage.ObjectChunkTest do
  use Legendary.ObjectStorage.DataCase

  import Legendary.ObjectStorage.ObjectChunk

  alias Legendary.ObjectStorage.ObjectChunk

  describe "changeset/2" do
    test "requires path, part_number, and body" do
      chunk = %ObjectChunk{path: "test.txt", part_number: 1, body: "hello!"}

      assert changeset(chunk, %{}).valid?
      refute changeset(chunk, %{path: nil}).valid?
      refute changeset(chunk, %{body: nil}).valid?
      refute changeset(chunk, %{part_number: nil}).valid?
    end
  end

  describe "etag/1" do
    test "is the same if the path, part, and inserted_at are same" do
      chunk = %{path: "hello-world", part_number: 1, inserted_at: DateTime.utc_now()}
      assert etag(chunk) == etag(chunk)
    end

    test "is different if the path, part, or inserted_at are different" do
      chunk = %{path: "hello-world", part_number: 1, inserted_at: DateTime.utc_now()}

      refute etag(chunk) == etag(%{chunk | path: "bye-for-now"})
      refute etag(chunk) == etag(%{chunk | part_number: 2})
      refute etag(chunk) == etag(%{chunk | inserted_at: DateTime.utc_now() |> DateTime.add(10)})
    end
  end
end
