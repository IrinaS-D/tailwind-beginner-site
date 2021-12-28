defmodule Legendary.ObjectStorage.ObjectsTest do
  use Legendary.ObjectStorage.DataCase

  alias Legendary.ObjectStorage.{Object, ObjectChunk, Objects}

  test "get_object/1 returns the object with given id" do
    object =
      %Object{path: "hello.txt"}
      |> Repo.insert!()
    assert Objects.get_object(object.path) == {:ok, object}
  end

  describe "get_or_initialize_object/1" do
    test "finds objects by path" do
      object =
        %Object{path: "hello.txt"}
        |> Repo.insert!()

      assert %{path: "hello.txt"} = Objects.get_or_initialize_object(object.path)
    end

    test "returns a blank Object if no object with the path exists" do
      assert %{body: nil, acl: nil} = Objects.get_or_initialize_object("bad-path")
    end
  end

  test "update_object/2 with valid data updates the object" do
    update_attrs = %{
      path: "test.txt",
      body: "Hello, world!",
      acl: "private"
    }

    assert {:ok, %Object{} = object} = Objects.update_object(%Object{}, update_attrs)
    assert object.path == "test.txt"
    assert object.body == "Hello, world!"
    assert object.acl == :private
  end

  test "update_object/2 with invalid data returns error changeset" do
    object =
      %Object{path: "test.txt", body: "Hello, world!"}
      |> Repo.insert!()
    assert {:error, %Ecto.Changeset{}} = Objects.update_object(object, %{body: ""})
    assert {:ok, object} == Objects.get_object(object.path)
    assert object.body == "Hello, world!"
  end

  describe "put_chunk/2" do
    test "adds a chunk to an object" do
      result = Objects.put_chunk(%{path: "hello-world.txt"}, %{part_number: 1, body: "Hello,"})
      assert {:ok, %ObjectChunk{part_number: 1, body: "Hello,", path: "hello-world.txt"}} = result
    end
  end

  describe "finalized_chunked_upload/2" do
    test "with contiguous chunks" do
      object = Repo.insert!(%Object{path: "hello-world.txt", acl: :public_read})
      chunk1 = Repo.insert!(%ObjectChunk{path: "hello-world.txt", part_number: 1, body: "Hello, "})
      chunk2 = Repo.insert!(%ObjectChunk{path: "hello-world.txt", part_number: 2, body: "world!"})
      etags = [ObjectChunk.etag(chunk1), ObjectChunk.etag(chunk2)]

      assert {
        :ok,
        %{
          update_object_body: {updated_objects_count, nil},
          remove_chunks: {removed_chunks_count, nil}
        }
      } = Objects.finalize_chunked_upload(object, etags)
      assert updated_objects_count == 1
      assert removed_chunks_count == 2
      assert {:ok, %Object{body: body}} = Objects.get_object("hello-world.txt")
      assert body == "Hello, world!"
    end

    test "with gap in chunks" do
      object = Repo.insert!(%Object{path: "hello-world.txt", acl: :public_read})
      _chunk1 = Repo.insert!(%ObjectChunk{path: "hello-world.txt", part_number: 1, body: "Hell"})
      _chunk3 = Repo.insert!(%ObjectChunk{path: "hello-world.txt", part_number: 3, body: " world!"})

      assert {
        :error,
        :check_chunks,
        "Missing chunks for chunked upload. Aborting.",
        _
      } = Objects.finalize_chunked_upload(object, [])
    end
  end

  test "delete_object/1 deletes the object" do
    object =
      %Object{path: "test.txt"}
      |> Repo.insert!()
    assert {:ok, %Object{path: "test.txt"}} = Objects.delete_object(object)
    assert {:error, :not_found} = Objects.get_object(object.path)
  end
end
