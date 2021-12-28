defmodule Legendary.ObjectStorageWeb.UploadController do
  use Legendary.ObjectStorageWeb, :controller

  alias Ecto.Changeset
  alias Legendary.ObjectStorage.Objects
  alias Legendary.ObjectStorage.{Object, ObjectChunk}
  alias Legendary.ObjectStorageWeb.CheckSignatures

  action_fallback ObjectStorageWeb.FallbackController

  plug CheckSignatures when action not in [:show]

  def show(conn, %{"path" => path_parts}) do
    case Objects.get_object(Enum.join(path_parts, "/")) do
      {:ok, %{acl: :public_read} = object} ->
        conn
        |> put_resp_content_type(MIME.from_path(object.path) , "binary")
        |> send_resp(200, object.body)
      {:ok, %{acl: :private} = object} ->
        conn_checked = CheckSignatures.call(conn)

        if conn_checked.halted do
          conn
          |> put_status(:not_found)
          |> render("not_found.xml")
        else
          conn
          |> put_resp_content_type(MIME.from_path(object.path) , "binary")
          |> send_resp(200, object.body)
        end
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.xml")
    end
  end

  def put_object(
    conn,
    %{"path" => path_parts, "uploadId" => _id, "partNumber" => part_number}
  ) when is_binary(part_number), do: put_chunk(conn, path_parts, part_number)

  def put_object(conn, %{"path" => path_parts}), do: do_put_object(conn, path_parts)

  def delete_object(conn, %{"path" => path_parts}) do
    with {:ok, object} <- Objects.get_object(Enum.join(path_parts, "/")),
         {:ok, %Object{}} <- Objects.delete_object(object)
    do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.xml")
    end
  end

  defp put_chunk(conn, path_parts, part_number) do
    path = Enum.join(path_parts, "/")

    attrs = %{
      body: conn.assigns.body,
      part_number: part_number
    }

    with {:ok, object} <- Objects.get_object(path),
         {:ok, chunk} <- Objects.put_chunk(object, attrs)
    do
      conn
      |> put_resp_header("etag", ObjectChunk.etag(chunk))
      |> send_resp(:ok, "")
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render("not_found.xml")
      {:error, %Changeset{} = changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("error.xml", changeset: changeset)
    end
  end

  defp do_put_object(conn, path_parts) do
    path = Enum.join(path_parts, "/")

    attrs = %{
      path: path,
      body: conn.assigns.body,
      acl: get_first_request_header(conn, "x-amz-acl", "private"),
    }

    object = Objects.get_or_initialize_object(path)

    case Objects.update_object(object, attrs) do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/text")
        |> send_resp(:ok, "")
      {:error, %Changeset{} = changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("error.xml", changeset: changeset)
    end
  end
end
