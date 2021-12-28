defmodule Legendary.ObjectStorageWeb.CheckSignaturesTest do
  use Legendary.ObjectStorageWeb.ConnCase

  import Legendary.ObjectStorageWeb.CheckSignatures
  import Mox

  alias Legendary.ObjectStorageWeb.CheckSignatures.MockSignatureGenerator

  test "init/1 returns opts", do: assert init(nil) == nil

  describe "call/2" do
    test "with a good signature in header it continues", %{conn: conn} do
      MockSignatureGenerator
      |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)
      |> expect(:parse_authorization_header, fn _ -> %{"Signature" => "good-sig"} end)

      refute call(conn, nil).halted
    end

    test "with a good signature in query params it continues", %{conn: conn} do
      MockSignatureGenerator
      |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)

      conn = %{conn | query_params: %{"X-Amz-Signature" => "good-sig"}}

      refute call(conn, nil).halted
    end

    test "with a bad signature it halts", %{conn: conn} do
      MockSignatureGenerator
      |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)

      conn = %{conn | query_params: %{"X-Amz-Signature" => "bad-sig"}}

      assert call(conn, nil).halted
    end

    test "with an expired request it halts", %{conn: conn} do
      conn = %{conn | query_params: %{"X-Amz-Date" => "19000101T000000Z", "X-Amz-Expires" => 3600}}

      assert call(conn, nil).halted
    end
  end
end
