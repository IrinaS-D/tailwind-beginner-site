ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Legendary.ObjectStorage.Repo, :manual)

Mox.defmock(
  Legendary.ObjectStorageWeb.CheckSignatures.MockSignatureGenerator,
  for: Legendary.ObjectStorageWeb.CheckSignatures.SignatureGenerator
)
