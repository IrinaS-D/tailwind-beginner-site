defmodule Legendary.ObjectStorage.Objects do
  @moduledoc """
  The Objects context.
  """

  import Ecto.Query, warn: false

  alias Legendary.ObjectStorage.{Object, ObjectChunk}
  alias Legendary.ObjectStorage.Repo

  @doc """
  Gets a single object.

  Raises if the Object does not exist.

  ## Examples

      iex> get_object!(123)
      %Object{}

  """
  @spec get_object(binary) :: {:ok, Object.t()} | {:error, :not_found}
  def get_object(path) do
    from(
      obj in Object,
      where: obj.path == ^path
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      %Object{} = object -> {:ok, object}
    end
  end

  @spec get_or_initialize_object(binary) :: Object.t()
  def get_or_initialize_object(path) do
    case get_object(path) do
      {:ok, object} ->
        object
      {:error, :not_found} ->
        %Object{}
    end
  end

  @doc """
  Updates a object.

  ## Examples

      iex> update_object(object, %{field: new_value})
      {:ok, %Object{}}

      iex> update_object(object, %{field: bad_value})
      {:error, ...}

  """
  @spec update_object(Object.t(), Map.t()) :: {:ok, Object.t()} | {:error, Ecto.Changeset.t()}
  def update_object(%Object{} = object, attrs) do
    object
    |> Object.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def put_chunk(%{path: path}, %{part_number: part_number, body: body}) do
    %ObjectChunk{}
    |> ObjectChunk.changeset(%{
      path: path,
      part_number: part_number,
      body: body
    })
    |> Repo.insert(conflict_target: [:path, :part_number], on_conflict: {:replace, [:body]})
  end

  def finalize_chunked_upload(%Object{path: path}, request_etags) do
    chunk_query =
      from(chunk in ObjectChunk, where: chunk.path == ^path)

    part_number_range =
      chunk_query
      |> select([c], [
        min_chunk: fragment("min(part_number)"),
        max_chunk: fragment("max(part_number)"),
        chunk_count: fragment("count(part_number)")
      ])
      |> Repo.one()
      |> Enum.into(%{})

    Ecto.Multi.new()
    |> Ecto.Multi.run(:check_chunks, fn _repo, _ ->
      case part_number_range do
        %{min_chunk: 1, max_chunk: max_chunk, chunk_count: max_chunk} ->
          {:ok, part_number_range}
        _ ->
          {:error, "Missing chunks for chunked upload. Aborting."}
      end
    end)
    |> Ecto.Multi.run(:check_etags, fn _repo, _ ->
      db_etags =
        chunk_query
        |> Repo.all()
        |> Enum.map(&ObjectChunk.etag/1)
        |> MapSet.new()

      if db_etags == MapSet.new(request_etags) do
        {:ok, request_etags}
      else
        {:error, "ETags in request do not match parts in database."}
      end
    end)
    |> Ecto.Multi.update_all(:update_object_body, fn %{} ->
      from(
        object in Object,
        where: object.path == ^path,
        join: new_body in fragment("""
          SELECT string_agg(body, '') as body
          FROM (
            SELECT body
            FROM storage_object_chunks
            WHERE path = ?
            ORDER BY part_number ASC
          ) as body_pieces
        """, ^path),
        update: [set: [body: new_body.body]]
      )
    end, [])
    |> Ecto.Multi.delete_all(:remove_chunks, chunk_query)
    |> Repo.transaction()
  end

  @doc """
  Deletes a Object.

  ## Examples

      iex> delete_object(object)
      {:ok, %Object{}}

      iex> delete_object(object)
      {:error, ...}

  """
  def delete_object(%Object{} = object) do
    Repo.delete(object)
  end
end
