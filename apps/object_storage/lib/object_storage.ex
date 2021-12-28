defmodule Legendary.ObjectStorage do
  @moduledoc """
  Legendary.ObjectStorage keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def bucket_name, do: Application.get_env(:object_storage, :bucket_name)
end
