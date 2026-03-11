module "connectivity_rbac" {
  count = length(var.role_assignments_azure_resource_manager) > 0 ? 1 : 0

  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"

  enable_telemetry = var.enable_telemetry

  role_assignments_azure_resource_manager = local.role_assignments_azure_resource_manager_effective

  # Ensure role assignments wait for any RGs created in this stack.
  depends_on = [module.resource_groups]
}
