defmodule ObjectStorageWeb.UploadControllerTest do
  use Legendary.ObjectStorageWeb.ConnCase

  alias Legendary.ObjectStorage.{Object, Repo}
  alias Legendary.ObjectStorageWeb.CheckSignatures.{MockSignatureGenerator, SignatureGenerator}

  import Mox

  def put_request(conn, path, acl, body, params \\ %{}, content_type \\ "text/plain") do
    conn
    |> put_req_header("x-amz-acl", acl)
    |> put_req_header("content-type", content_type)
    |> put(
      Routes.upload_path(conn, :put_object, path, params),
      body
    )
  end

  describe "show object" do
    test "returns 404 if the object is private and sig check fails", %{conn: conn} do
      expect_signature_checks_and_fail()

      Repo.insert!(%Object{path: "secret.txt", acl: :private, body: "Ssh!"})

      conn = get(conn, Routes.upload_path(conn, :show, ["secret.txt"]))

      assert response(conn, 404)
      assert response_content_type(conn, :xml)
    end

    test "returns 404 if the object is private and there are no sig headers", %{conn: conn} do
      verify_on_exit!()

      MockSignatureGenerator
      |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)
      |> expect(:parse_authorization_header,
        fn header ->
          SignatureGenerator.parse_authorization_header(header)
        end
      )

      Repo.insert!(%Object{path: "secret.txt", acl: :private, body: "Ssh!"})

      conn = get(conn, Routes.upload_path(conn, :show, ["secret.txt"]))

      assert response(conn, 404)
      assert response_content_type(conn, :xml)
    end

    test "returns the object if the object is private but the sig check passes", %{conn: conn} do
      expect_signature_checks_and_pass()

      Repo.insert!(%Object{path: "secret.txt", acl: :private, body: "Ssh!"})

      conn = get(conn, Routes.upload_path(conn, :show, ["secret.txt"]))

      assert text_response(conn, 200) == "Ssh!"
    end
  end

  describe "put object" do
    setup do
      expect_signature_checks_and_pass()
    end

    test "renders object when data is valid", %{conn: conn} do
      conn = put_request(conn, ["test.txt"], "public_read", "Hello, world!")
      assert text_response(conn, 200) == ""

      conn = get(conn, Routes.upload_path(conn, :show, ["test.txt"]))

      assert "Hello, world!" = text_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put_request(conn, ["test.txt"], "bad_acl", "Hello, world!")
      assert response(conn, 400) =~ "<Code>InvalidArgument</Code>"
    end
  end

  describe "put chunk" do
    setup [:create_object]

    setup do
      expect_signature_checks_and_pass()
    end

    test "can put a chunk if you give a part number", %{conn: conn, object: object} do
      conn = put_request(conn, [object.path], "public_read", "Hello, world!", %{"partNumber" => 1, "uploadId" => 1})
      assert response(conn, 200)
    end

    test "returns a 404 if the path is wrong", %{conn: conn} do
      conn = put_request(conn, ["wrong"], "public_read", "Hello, world!", %{"partNumber" => 1, "uploadId" => 1})
      assert response(conn, 404)
    end

    test "returns a 400 Bad Request if the body is missing", %{conn: conn, object: object} do
      conn = put_request(conn, [object.path], "public_read", nil, %{"partNumber" => 1, "uploadId" => 1})
      assert response(conn, 400) =~ "<Code>InvalidArgument</Code>"
    end
  end

  describe "delete object" do
    setup [:create_object]

    setup do
      expect_signature_checks_and_pass()
    end

    test "deletes chosen object", %{conn: conn} do
      conn = delete(conn, Routes.upload_path(conn, :delete_object, ["test.txt"]))
      assert response(conn, 204)

      conn = get(conn, Routes.upload_path(conn, :show, ["test.txt"]))
      assert response(conn, 404)
    end

    test "returns 404 if the path does not exist", %{conn: conn} do
      conn = delete(conn, Routes.upload_path(conn, :delete_object, ["bad-path"]))
      assert response(conn, 404)
    end
  end

  defp create_object(_) do
    %{object: %Object{path: "test.txt"} |> Repo.insert!()}
  end
end
