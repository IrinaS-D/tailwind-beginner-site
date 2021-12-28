defmodule Legendary.ObjectStorage.ObjectTest do
  use Legendary.ObjectStorage.DataCase

  import Legendary.ObjectStorage.Object

  alias Legendary.ObjectStorage.Object

  describe "changeset/2" do
    test "does not require body for multipart uploads" do
      assert changeset(%Object{}, %{acl: "public_read", path: "test", uploads: "1"}) .valid?
    end

    test "requires a body if single part upload" do
      refute changeset(%Object{}, %{acl: "public_read", path: "test"}).valid?
    end
  end
end
