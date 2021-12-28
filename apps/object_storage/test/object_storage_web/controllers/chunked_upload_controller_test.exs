defmodule Legendary.ObjectStorageWeb.ChunkedUploadControllerTest do
  use Legendary.ObjectStorageWeb.ConnCase

  alias Legendary.ObjectStorage.{Object, ObjectChunk, Repo}

  setup do
    expect_signature_checks_and_pass()
  end

  def post_request(conn, path, opts \\ []) do
    content_type = Keyword.get(opts, :content_type, "text/plain")
    acl = Keyword.get(opts, :acl, "public_read")
    params = Keyword.get(opts, :params, %{})
    body = Keyword.get(opts, :body)

    conn
    |> put_req_header("x-amz-acl", acl)
    |> put_req_header("content-type", content_type)
    |> post(Routes.chunked_upload_path(conn, :chunked_upload, path, params), body)
  end

  describe "start" do
    test "initiates an upload with proper variables", %{conn: conn} do
      conn = post_request(conn, ["new-multipart-upload"], params: %{"uploads" => "1"})

      assert response(conn, 200)
    end

    test "return 400 Bad Request with a wrong ACL", %{conn: conn} do
      conn = post_request(conn, ["new-multipart-upload"], acl: "wrong", params: %{"uploads" => "1"})

      assert response(conn, 400)
    end
  end

  describe "finalize" do
    test "finalizes an upload by pass", %{conn: conn} do
      Repo.insert!(%Object{path: "new-multipart-upload", acl: :public_read})
      chunk = Repo.insert!(%ObjectChunk{path: "new-multipart-upload", part_number: 1})

      conn =
        post_request(
          conn,
          ["new-multipart-upload"],
          params: %{"uploadId" => "1"},
          body: """
          <?xml version="1.0" encoding="UTF-8"?>
          <CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Part>
                <ETag>#{ObjectChunk.etag(chunk)}</ETag>
                <PartNumber>1</PartNumber>
            </Part>
            ...
          </CompleteMultipartUpload>
          """
        )

      assert response(conn, 200)
    end

    test "returns a 400 Bad Request if chunks are missing", %{conn: conn} do
      Repo.insert!(%Object{path: "new-multipart-upload", acl: :public_read})

      conn = post_request(conn, ["new-multipart-upload"], params: %{"uploadId" => "1"})

      assert response(conn, 400)
    end

    test "returns a 404 if no such object exists", %{conn: conn} do
      conn = post_request(conn, ["new-multipart-upload"], params: %{"uploadId" => "1"})

      assert response(conn, 404)
    end
  end
end
