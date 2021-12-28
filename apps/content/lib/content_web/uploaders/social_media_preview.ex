defmodule Legendary.ContentWeb.Uploaders.SocialMediaPreview do
  @moduledoc """
  Uploader definition for social media preview images.
  """
  use Waffle.Definition

  @versions [:original]
  @acl :public_read

  # Override the persisted filenames:
  def filename(version, _) do
    Atom.to_string(version)
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, %{name: name}}) do
    "public_uploads/content/posts/preview_images/#{name}"
  end
end
