defmodule Legendary.CoreWeb.Base64Uploads do
  @moduledoc """
  Utilities for converting data uris and base64 strings to Plug.Upload structs
  so they can be processed in the same way as files submitted by multipart forms.
  """
  def data_uri_to_upload(str) do
    parse_result =
      str
      |> URI.parse()
      |> URL.Data.parse()

    case parse_result do
      %{data: {:error, _}} ->
        :error
      %{data: data, mediatype: content_type} ->
        binary_to_upload(data, content_type)
    end
  end

  def base64_to_upload(str, content_type) do
    case Base.decode64(str) do
      {:ok, data} -> binary_to_upload(data, content_type)
      _ -> :error
    end
  end

  def binary_to_upload(binary, content_type) do
    file_extension = file_extension_for_content_type(content_type)

    with {:ok, path} <- Plug.Upload.random_file("upload"),
         {:ok, file} <- File.open(path, [:write, :binary]),
         :ok <- IO.binwrite(file, binary),
         :ok <- File.close(file) do
      %Plug.Upload{
        path: path,
        content_type: content_type,
        filename: "#{Path.basename(path)}#{file_extension}"
      }
    end
  end

  defp file_extension_for_content_type(content_type) do
    case MIME.extensions(content_type) do
      [] -> ""
      [ext|_] -> ".#{ext}"
    end
  end
end
