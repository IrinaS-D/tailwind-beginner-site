defmodule Legendary.ObjectStorageWeb.CheckSignatures do
  @moduledoc """
  A plug for checking authorization signatures either in the headers or query params.
  """
  @behaviour Plug

  import Plug.Conn
  import Legendary.ObjectStorageWeb.Helpers, only: [get_first_request_header: 2, amz_date_parse: 1]

  alias Legendary.ObjectStorageWeb.CheckSignatures.SignatureGenerator

  def init(opts) do
    opts
  end

  def call(conn, _opts \\ []) do
    with true <- fresh_request(conn),
         {:ok, correct_signature} <- signature_generator().correct_signature_for_conn(conn),
         {:ok, actual_signature} <- actual_signature_for_conn(conn),
         true <- Plug.Crypto.secure_compare(correct_signature, actual_signature)
    do
      conn
    else
      _ ->
        conn
        |> send_resp(:forbidden, "Forbidden")
        |> halt()
    end
  end

  def actual_signature_for_conn(%{query_params: %{"X-Amz-Signature" => actual_signature}}) do
    {:ok, actual_signature}
  end

  def actual_signature_for_conn(conn) do
    parsed_header =
      conn
      |> get_first_request_header("authorization")
      |> signature_generator().parse_authorization_header()

    case parsed_header do
      %{"Signature" => actual_signature} ->
        {:ok, actual_signature}
      _ ->
        {:error, :no_signature}
    end
  end

  defp signature_generator() do
    Application.get_env(:object_storage, :signature_generator, SignatureGenerator)
  end

  @one_week 60 * 60 * 24 * 7
  defp fresh_request(%{
    query_params: %{
      "X-Amz-Expires" => expires_in,
      "X-Amz-Date" => request_timestamp,
    }
  }) when is_integer(expires_in) do
    request_epoch =
      request_timestamp
      |> amz_date_parse()
      |> :calendar.datetime_to_gregorian_seconds()

    now_epoch =
      :calendar.universal_time()
      |> :calendar.datetime_to_gregorian_seconds()

    request_age = now_epoch - request_epoch

    request_age < expires_in && expires_in < @one_week
  end

  defp fresh_request(_), do: true
end
