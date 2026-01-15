provider "azurerm" {
  features {}

  # remove before sharing with CX: hardcoded subscription/tenant identifiers
  subscription_id = "e3cb4605-49f4-472c-bf66-085b7510a36e"
  tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"
}

provider "azapi" {
  # remove before sharing with CX: hardcoded subscription/tenant identifiers
  subscription_id = "e3cb4605-49f4-472c-bf66-085b7510a36e"
  tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"
}

# The ALZ provider is used by the AVM ALZ module.
# We keep it minimal and follow the upstream examples.
provider "alz" {
  # Mirror AVM `examples/default`: use local library override content from ./lib.
  # This lets us customize architecture/policy artifacts without forking the whole module.
  library_overwrite_enabled = true

  library_references = [
    {
      path = "platform/alz"
      # The alz provider requires `ref` when `path` is set.
      # Pin this to the same ref as the upstream example we based this on.
      ref = "2025.09.0"
    },
    {
      custom_url = "${path.root}/lib"
    }
  ]
}
