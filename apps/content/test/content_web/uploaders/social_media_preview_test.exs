defmodule Legendary.ContentWeb.Uploaders.SocialMediaPreviewTest do
  use Legendary.Content.DataCase

  import Legendary.ContentWeb.Uploaders.SocialMediaPreview

  describe "filename/2" do
    test "" do
      assert filename(:original, {%{file_name: "original.png"}, nil}) =~ "original"
    end
  end

  describe "storage_dir/2" do
    test "" do
      assert storage_dir(nil, {nil, %{name: "test-slug"}}) =~ "public_uploads/content/posts/preview_images/test-slug"
    end
  end
end
