defmodule Legendary.ObjectStorageWeb.Routes do
  @moduledoc """
  Routes for the object storage engine.
  """

  import Legendary.ObjectStorage, only: [bucket_name: 0]

  defmacro __using__(_opts \\ []) do
    quote do
      scope "/", Legendary.ObjectStorageWeb do
        pipe_through :api

        get "/#{bucket_name()}/*path", UploadController, :show
        put "/#{bucket_name()}/*path", UploadController, :put_object
        delete "/#{bucket_name()}/*path", UploadController, :delete_object

        post "/#{bucket_name()}/*path", ChunkedUploadController, :chunked_upload
      end
    end
  end
end
