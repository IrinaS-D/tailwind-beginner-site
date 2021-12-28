defmodule Legendary.Content.Posts.PreviewImages do
  @moduledoc """
  Handles storing social media preview images which are submitted as data uris
  in the social_media_preview_image field.
  """
  alias Ecto.Changeset
  alias Legendary.ContentWeb.Uploaders.SocialMediaPreview
  alias Legendary.CoreWeb.Base64Uploads

  def handle_preview_image_upload(changeset, attrs) do
    upload =
      case attrs do
        %{"social_media_preview_image" => data} when is_binary(data) ->
          Base64Uploads.data_uri_to_upload(data)
        _ -> nil
      end

    case upload do
      nil ->
        changeset
      %Plug.Upload{} ->
        name = Changeset.get_field(changeset, :name)
        {:ok, _filename} = SocialMediaPreview.store({upload, %{name: name}})
        changeset
      :error ->
        changeset
        |> Changeset.add_error(:social_media_preview_image, "is malformed")
    end
  end
end
