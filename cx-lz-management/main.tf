data "azapi_client_config" "current" {}

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.15.0"

  location          = var.location
  architecture_name = var.architecture_name

  # remove before sharing with CX: hardcoded tenant/subscription identifiers
  # Usually this is the tenant root (GUID) so the module can create the root management group under the tenant.
  parent_resource_id = "9a9712e7-1382-4528-8495-b52ae7688acb"

  # remove before sharing with CX: hardcoded subscription identifiers
  # Keys are arbitrary; values control the target management group.
  subscription_placement = {
    management = {
      subscription_id       = "e3cb4605-49f4-472c-bf66-085b7510a36e"
      management_group_name = "management"
    }
    production = {
      subscription_id       = "1d70f8ca-f7e4-4d69-98fe-53959be8f10a"
      management_group_name = "prod"
    }
    connectivity = {
      subscription_id       = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
      management_group_name = "connectivity"
    }
  }

  # We’ll add these incrementally as we start customizing assignments.
  # policy_default_values = {}

  # NOTE: `policy_assignments_to_modify` can ONLY tweak properties (identity/params/enforcement/etc.)
  # of policy assignments that already exist in the chosen ALZ architecture library.
  # To ADD a brand new assignment (like the CIS initiative) we must extend the ALZ library under `./lib/`
  # (or use a dedicated "add policy assignments" input, if/when the module exposes one).
  #
  # We'll re-introduce the CIS assignment once implemented via the correct mechanism.
  # policy_assignments_to_modify = {}

  # management_group_role_assignments = {}
  # custom_role_definitions         = {}
}
