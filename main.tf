## AVM schema pass-through
# This repo intentionally stays close to the upstream AVM pattern module by
# passing `virtual_wan_settings` and `virtual_hubs` through directly.

module "resource_groups" {
  for_each = var.resource_groups

  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags

  enable_telemetry = false
}

data "azurerm_resource_group" "rg" {
  for_each = var.existing_resource_groups

  name = each.value.name
}

module "expressroute_circuits" {
  for_each = var.expressroute_circuits

  source = "./modules/expressroute_circuit"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), try(module.resource_groups[each.value.resource_group_key].location, data.azurerm_resource_group.rg[each.value.resource_group_key].location))
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  sku = each.value.sku

  tags             = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))
  exr_circuit_tags = try(each.value.exr_circuit_tags, null)

  service_provider_name          = try(each.value.service_provider_name, null)
  peering_location               = try(each.value.peering_location, null)
  bandwidth_in_mbps              = try(each.value.bandwidth_in_mbps, null)
  express_route_port_resource_id = try(each.value.express_route_port_resource_id, null)
  bandwidth_in_gbps              = try(each.value.bandwidth_in_gbps, null)

  allow_classic_operations = try(each.value.allow_classic_operations, false)
  authorization_key        = try(each.value.authorization_key, null)

  peerings                             = try(each.value.peerings, {})
  express_route_circuit_authorizations = try(each.value.express_route_circuit_authorizations, {})
  er_gw_connections                    = try(each.value.er_gw_connections, {})
  vnet_gw_connections                  = try(each.value.vnet_gw_connections, {})
  circuit_connections                  = try(each.value.circuit_connections, {})

  diagnostic_settings = try(each.value.diagnostic_settings, {})
  role_assignments    = try(each.value.role_assignments, {})
  lock                = try(each.value.lock, null)

  enable_telemetry = try(each.value.enable_telemetry, true)
}

module "firewall_policies" {
  for_each = var.firewall_policies

  source = "./modules/fwpolicy"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))

  firewall_policy_sku = try(each.value.firewall_policy_sku, "Standard")
  enable_telemetry    = try(each.value.enable_telemetry, false)

  rule_collection_groups = try(each.value.rule_collection_groups, {})
}

data "azurerm_firewall_policy" "existing" {
  for_each = var.existing_firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), try(module.resource_groups[each.value.resource_group_key].location, data.azurerm_resource_group.rg[each.value.resource_group_key].location))
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))
}

data "azurerm_network_security_group" "existing" {
  for_each = var.existing_network_security_groups

  name                = each.value.name
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)
}

module "alz_connectivity" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  count = 1

  providers = {
    azurerm = azurerm.wan
    azapi   = azapi.wan
  }

  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  default_naming_convention          = var.default_naming_convention
  default_naming_convention_sequence = var.default_naming_convention_sequence
  retry                              = var.retry
  timeouts                           = var.timeouts

  private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix = var.private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix

  virtual_wan_settings = var.virtual_wan_settings
  virtual_hubs         = local.virtual_hubs_effective
}

