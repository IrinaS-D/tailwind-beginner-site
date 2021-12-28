defmodule Legendary.ObjectStorage.Repo do
  use Ecto.Repo,
    otp_app: :object_storage,
    adapter: Ecto.Adapters.Postgres
end
