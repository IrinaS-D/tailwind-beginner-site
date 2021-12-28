defmodule Legendary.ObjectStorageWeb.CheckSignatures.SignatureGenerator do
  @moduledoc """
  Can generate a signature based on an incoming request so that it can be verified
  against the signature header or parameter submitted.
  """

  import Legendary.ObjectStorageWeb.Helpers, only: [get_first_request_header: 2, amz_date_parse: 1]

  alias ExAws.{
    Auth,
    Auth.Credentials,
    Auth.Signatures,
    Request.Url
  }

  alias ExAws.Auth.Utils, as: AuthUtils
  alias ExAws.S3.Utils, as: S3Utils

  alias Plug.Conn

  @callback correct_signature_for_conn(Conn.t()) :: {:ok, String.t()}
  @callback parse_authorization_header(String.t()) :: Map.t()

  @signature_in_query_pattern ~r/(&X-Amz-Signature=[0-9a-fA-F]+)|(X-Amz-Signature=[0-9a-fA-F]+&)/
  def correct_signature_for_conn(conn) do
    config = ExAws.Config.new(:s3)
    url = url_to_sign(conn, config)
    sanitized_query_string = Regex.replace(@signature_in_query_pattern, conn.query_string, "")
    headers = filtered_headers(conn)

    case headers do
      :error ->
        :error

      _ ->
        {:ok, signature(
          conn.method |> String.downcase() |> String.to_atom(),
          url,
          sanitized_query_string,
          headers,
          body_for_request(conn),
          conn |> request_datetime() |> amz_date_parse(),
          config
        )}
    end
  end

  def parse_authorization_header(nil), do: :error
  def parse_authorization_header(header) do
    ["AWS4-HMAC-SHA256", params] = String.split(header, " ")

    params
    |> String.split(",")
    |> Enum.map(& String.split(&1, "="))
    |> Enum.map(fn [k, v] -> {k, v} end)
    |> Enum.into(%{})
  end

  defp url_to_sign(%{params: %{"path" => path_parts}}, config) do
    object =
      path_parts
      |> Enum.join("/")
      |> S3Utils.ensure_slash()
    bucket = Application.get_env(:object_storage, :bucket_name)
    port = S3Utils.sanitized_port_component(config)
    "#{config[:scheme]}#{config[:host]}#{port}/#{bucket}#{object}"
  end

  defp request_datetime(%{params: %{"X-Amz-Date" => datetime}}), do: datetime
  defp request_datetime(conn), do: get_first_request_header(conn, "x-amz-date")

  defp filtered_headers(conn) do
    case filtered_header_names(conn) do
      :error -> :error
      signed_header_keys ->
        Enum.filter(conn.req_headers, fn {k, _v} -> k in signed_header_keys end)
    end
  end

  defp filtered_header_names(%{params: %{"X-Amz-SignedHeaders" => signed_header_string}}) do
    String.split(signed_header_string, ";")
  end
  defp filtered_header_names(conn) do
    header = get_first_request_header(conn, "authorization")

    if header do
      header
      |> parse_authorization_header()
      |> Map.get("SignedHeaders")
      |> String.split(";")
    else
      :error
    end
  end

  # Presigned URL, so do not include body (unknown when presigning) to sig calc
  defp body_for_request(%{params: %{"X-Amz-Signature" => _}}), do: nil
  # Otherwise, include body
  defp body_for_request(%{assigns: %{body: body}}), do: body

  defp signature(http_method, url, query, headers, body, datetime, config) do
    path = url |> Url.get_path(:s3) |> Url.uri_encode()
    request = Auth.build_canonical_request(http_method, path, query, headers, body)
    string_to_sign = string_to_sign(request, :s3, datetime, config)
    Signatures.generate_signature_v4("s3", config, datetime, string_to_sign)
  end

  defp string_to_sign(request, service, datetime, config) do
    request = AuthUtils.hash_sha256(request)

    """
    AWS4-HMAC-SHA256
    #{AuthUtils.amz_date(datetime)}
    #{Credentials.generate_credential_scope_v4(service, config, datetime)}
    #{request}
    """
    |> String.trim_trailing()
  end
end
