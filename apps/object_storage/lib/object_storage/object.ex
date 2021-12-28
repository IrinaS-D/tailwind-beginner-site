defmodule Legendary.ObjectStorage.Object do
  @moduledoc """
  One object/file in the object storage app.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @acl_values [:private, :public_read]

  schema "storage_objects" do
    field :acl, Ecto.Enum, values: @acl_values
    field :body, :binary
    field :path, :string

    timestamps()
  end

  @doc false
  def changeset(object, attrs \\ %{}) do
    attrs = format_acl(attrs)

    object
    |> cast(attrs, [:path, :body, :acl])
    |> validate_required([:path, :acl])
    |> validate_body_or_upload(attrs)
    |> validate_inclusion(:acl, @acl_values, message: "is not supported. Valid values are #{@acl_values |> Enum.map(&Atom.to_string/1) |> Enum.join(",")}.")
  end

  defp format_acl(%{acl: acl} = attrs) do
    %{attrs | acl: Recase.to_snake(acl)}
  end
  defp format_acl(attrs), do: attrs

  defp validate_body_or_upload(changeset, attrs) do
    case attrs do
      %{uploads: "1"} ->
        changeset
      _ ->
        validate_required(changeset, :body)
    end
  end
end
