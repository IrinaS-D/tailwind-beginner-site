defmodule Legendary.ObjectStorage.Test do
  use Legendary.ObjectStorage.DataCase

  alias Legendary.ObjectStorage

  describe "bucket_name/0" do
    test "returns the bucket name" do
      assert ObjectStorage.bucket_name() == "uploads"
    end
  end
end
