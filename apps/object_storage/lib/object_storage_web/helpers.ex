defmodule Legendary.ObjectStorageWeb.Helpers do
  @moduledoc """
  Utility functions which are used throughout ObjectStorageWeb.
  """

  alias Plug.Conn

  def get_first_request_header(conn, key, default \\ nil) do
    case Conn.get_req_header(conn, key) do
      [] -> default
      [hd|_] -> hd
    end
  end

  def parse_body(conn, _opts) do
    {:ok, body, conn} =
      conn
      |> Conn.read_body()

    Conn.assign(conn, :body, body)
  end

  def amz_date_parse(date_string) do
    format = ~r/^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})Z/
    [_|parts] = Regex.run(format, date_string)

    [year, month, day, hour, minute, second] =
      parts
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn {int, _} -> int end)

    {{year, month, day}, {hour, minute, second}}
  end
end
