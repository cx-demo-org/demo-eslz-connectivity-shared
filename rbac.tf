locals {
  rbac_enabled = length(var.role_assignments_azure_resource_manager) > 0

  role_assignments_azure_resource_manager_hydrated = {
    for assignment_key, assignment in var.role_assignments_azure_resource_manager : assignment_key => merge(
      # Strip helper key before passing through to AVM
      { for k, v in assignment : k => v if k != "scope_resource_group_key" },

      # Hydrate scope from resource group key when scope is not explicitly set
      (
        try(assignment.scope, null) != null ? {}
        : try(assignment.scope_resource_group_key, null) != null ? { scope = local.rg[assignment.scope_resource_group_key].id }
        : {}
      )
    )
  }
}

module "connectivity_rbac" {
  count = local.rbac_enabled ? 1 : 0

  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"

  enable_telemetry = var.enable_telemetry

  role_assignments_azure_resource_manager = local.role_assignments_azure_resource_manager_hydrated

  # Ensure role assignments wait for any RGs created in this stack.
  depends_on = [module.resource_groups]
}
