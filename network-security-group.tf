module "network_security_groups" {
  for_each = var.network_security_groups

  source = "Azure/avm-res-network-networksecuritygroup/azurerm"
  # Pin to an explicit version for reproducibility.
  # Update intentionally as part of dependency management.
  version = "0.5.1"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), try(module.resource_groups[each.value.resource_group_key].location, data.azurerm_resource_group.rg[each.value.resource_group_key].location))
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))

  enable_telemetry = var.enable_telemetry
}

data "azurerm_network_security_group" "existing" {
  for_each = var.existing_network_security_groups

  name                = each.value.name
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)
}
