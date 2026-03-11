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

# Single lookup map for all resource groups referenced by the deployment:
# merges RGs created by `module.resource_groups` and RGs sourced via `data.azurerm_resource_group.rg`.
locals {
  rg = merge(
    { for rg_key, rg_mod in module.resource_groups : rg_key => { id = rg_mod.resource_id, name = rg_mod.name, location = rg_mod.location, tags = coalesce(try(rg_mod.resource.tags, null), try(var.resource_groups[rg_key].tags, {})) } },
    { for rg_key, rg_data in data.azurerm_resource_group.rg : rg_key => { id = rg_data.id, name = rg_data.name, location = rg_data.location, tags = rg_data.tags } }
  )
}

module "expressroute_circuits" {
  for_each = var.expressroute_circuits

  source = "./modules/expressroute_circuit"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg[each.value.resource_group_key].location)
  resource_group_name = local.rg[each.value.resource_group_key].name

  sku = each.value.sku

  tags             = merge(local.rg[each.value.resource_group_key].tags, try(each.value.tags, {}))
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
  resource_group_name = local.rg[each.value.resource_group_key].name

  tags = merge(local.rg[each.value.resource_group_key].tags, try(each.value.tags, {}))

  builtins               = try(each.value.builtins, null)
  rule_collection_groups = try(each.value.rule_collection_groups, {})
}

data "azurerm_firewall_policy" "existing" {
  for_each = var.existing_firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
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
  virtual_hubs         = var.virtual_hubs
}

# Convenience locals derived from the AVM connectivity module outputs:
# - keep hub/firewall resource IDs by hub key
# - build a reverse lookup (hub id -> hub key) for cross-references.
locals {
  virtual_hub_ids          = module.alz_connectivity[0].virtual_hub_resource_ids
  virtual_hub_firewall_ids = module.alz_connectivity[0].firewall_resource_ids
  virtual_hub_keys_by_id   = { for hub_key, hub_id in local.virtual_hub_ids : hub_id => hub_key }
}

locals {
  firewall_policy_ids = merge(
    { for policy_key, policy_mod in module.firewall_policies : policy_key => policy_mod.id },
    { for policy_key, policy_data in data.azurerm_firewall_policy.existing : policy_key => policy_data.id }
  )
}

