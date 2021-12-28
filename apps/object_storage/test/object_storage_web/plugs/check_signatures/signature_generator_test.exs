defmodule Legendary.ObjectStorageWeb.CheckSignatures.SignatureGeneratorTest do
  use Legendary.ObjectStorageWeb.ConnCase

  import Legendary.ObjectStorageWeb.CheckSignatures.SignatureGenerator

  alias ExAws.S3

  require IEx

  describe "correct_signature_for_conn/1"do
    test "handles signature in authorization header" do
      conn =
        "PUT"
        |> build_conn("/uploads/sig-test.txt", %{"path" => ["sig-test.txt"]})
        |> put_req_header("host", "localhost:4000")
        |> put_req_header("x-amz-date", "20211015T000000Z")
        |> put_req_header("authorization", "AWS4-HMAC-SHA256 SignedHeaders=host;x-amz-date")
        |> assign(:body, "")

      assert {:ok, sig} = correct_signature_for_conn(conn)
      assert sig == "964cf3b50a10e020dee639986b2423118144e0ac4371f45a6ecf75adb043712b"
    end

    test "handles presigned url" do
      {:ok, url} = S3.presigned_url(ExAws.Config.new(:s3), :put, "uploads", "hello-world.txt")
      target_sig =
        url
        |> URI.parse()
        |> Map.get(:query)
        |> URI.decode_query()
        |> Map.get("X-Amz-Signature")

      conn =
        "PUT"
        |> build_conn(
          url,
          %{"path" => ["hello-world.txt"]}
        )
        |> assign(:body, nil)
        |> put_req_header("host", "localhost:4000")

      assert {:ok, sig} = correct_signature_for_conn(conn)
      assert sig == target_sig
    end
  end
end
