defmodule Legendary.ObjectStorageWeb.SignatureTestingUtilities do
  @moduledoc """
  Utilities that make it easier to test controller actions which require auth
  signatures.
  """
  import Mox

  alias Legendary.ObjectStorageWeb.CheckSignatures.MockSignatureGenerator

  def expect_signature_checks_and_pass do
    verify_on_exit!()

    MockSignatureGenerator
    |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)
    |> expect(:parse_authorization_header, fn _ -> %{"Signature" => "good-sig"} end)

    :ok
  end

  def expect_signature_checks_and_fail do
    verify_on_exit!()

    MockSignatureGenerator
    |> expect(:correct_signature_for_conn, fn _conn -> {:ok, "good-sig"} end)
    |> expect(:parse_authorization_header, fn _ -> %{"Signature" => "bad-sig"} end)

    :ok
  end
end
