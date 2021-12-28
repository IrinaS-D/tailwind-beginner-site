defmodule Legendary.ObjectStorageWeb.UploadView do
  use Legendary.ObjectStorageWeb, :view
  alias Ecto.Changeset
  alias Legendary.ObjectStorage

  def render("initiate_multipart_upload.xml", %{object: object}) do
    ~E"""
    <?xml version="1.0" encoding="UTF-8"?>
    <InitiateMultipartUploadResult>
      <Bucket><%= ObjectStorage.bucket_name() %></Bucket>
      <Key><%= object.path %></Key>
      <UploadId><%= object.id %></UploadId>
    </InitiateMultipartUploadResult>
    """
    |> safe_to_string()
  end

  def render("error.xml", assigns) do
    errors =
      case assigns do
        %{message: message} -> message
        %{changeset: changeset} ->
          changeset.errors
          |> Enum.map(fn {key, {message, _}} ->
            "#{key}: #{message}"
          end)
          |> Enum.join(", ")
      end

    code = Map.get(assigns, :code, "InvalidArgument")

    path =
      case assigns do
        %{changeset: changeset} ->
          Changeset.get_field(changeset, :path)
        %{path: path} ->
          path
      end


    ~E"""
    <?xml version="1.0" encoding="UTF-8"?>
    <Error>
      <Code><%= code %></Code>
      <Message><%= errors %></Message>
      <Resource><%= path %></Resource>
      <RequestId>DEADBEEF</RequestId>
    </Error>
    """
    |> safe_to_string()
  end

  def render("not_found.xml", _assigns) do
    ~E"""
    <?xml version="1.0" encoding="UTF-8"?>
    <Error>
      <Code>NoSuchKey</Code>
    </Error>
    """
    |> safe_to_string()
  end
end
