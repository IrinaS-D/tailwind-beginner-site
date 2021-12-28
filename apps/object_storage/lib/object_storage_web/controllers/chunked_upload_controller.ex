defmodule Legendary.ObjectStorageWeb.ChunkedUploadController do
  use Legendary.ObjectStorageWeb, :controller

  alias Ecto.Changeset
  alias Legendary.ObjectStorage.Objects

  plug :put_view, Legendary.ObjectStorageWeb.UploadView
  plug Legendary.ObjectStorageWeb.CheckSignatures when action not in [:show]

  def chunked_upload(conn, %{"path" => path_parts, "uploads" => "1"}), do: start(conn, path_parts)
  def chunked_upload(conn, %{"path" => path_parts, "uploadId" => id}) when is_binary(id), do: finalize(conn, path_parts, id)

  defp start(conn, path_parts) do
    path = Enum.join(path_parts, "/")

    attrs = %{
      path: path,
      acl: get_first_request_header(conn, "x-amz-acl", "private"),
      uploads: "1"
    }

    object = Objects.get_or_initialize_object(path)

    case Objects.update_object(object, attrs) do
      {:ok, updated_object} ->
        render(conn, "initiate_multipart_upload.xml", %{object: updated_object})
      {:error, %Changeset{} = changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("error.xml", changeset: changeset)
    end
  end

  defp finalize(conn, path_parts, _id) do
    path = Enum.join(path_parts, "/")

    with {:ok, object} <- Objects.get_object(path),
         {:ok, etags} <- extract_etags(conn),
         {:ok, _} <- Objects.finalize_chunked_upload(object, etags) do
        send_resp(conn, :ok, "")
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.xml")
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> render("error.xml", message: message, code: "InvalidPart", path: path)
      {:error, _, message, _} ->
        conn
        |> put_status(:bad_request)
        |> render("error.xml", message: message, code: "InvalidPart", path: path)
    end
  end

  defp extract_etags(%{assigns: %{body: body}}) do
    xpath =
      %SweetXpath{
        path: '//Part/ETag/text()',
        is_value: true,
        cast_to: false,
        is_list: true,
        is_keyword: false
      }

    try do
      {:ok,
        body
        |> SweetXml.parse(quiet: true)
        |> SweetXml.xpath(xpath)
        |> Enum.map(&to_string/1)
      }
    catch
      :exit, _ ->
        {:error, "Missing etags for chunked upload."}
    end
  end

  defp extract_etags(_), do: {:error, "Missing etags for chunked upload."}
end
