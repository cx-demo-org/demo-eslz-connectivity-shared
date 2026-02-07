locals {
  virtual_wan_sku = try(var.virtual_wan.sku, "Standard")
  virtual_wan_tags = var.virtual_wan == null ? {} : merge(
    try(local.rg[var.virtual_wan.resource_group_key].tags, {}),
    try(var.virtual_wan.tags, {})
  )
}

resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

data "azurerm_resource_group" "rg" {
  for_each = var.existing_resource_groups

  name = each.value.name
}

locals {
  rg = merge(
    { for rg_key, rg_res in azurerm_resource_group.rg : rg_key => { name = rg_res.name, location = rg_res.location, tags = rg_res.tags } },
    { for rg_key, rg_data in data.azurerm_resource_group.rg : rg_key => { name = rg_data.name, location = rg_data.location, tags = rg_data.tags } }
  )
}

module "virtual_wan" {
  count = var.virtual_wan == null ? 0 : 1

  source = "./modules/vwan"

  providers = {
    azurerm = azurerm.wan
    azapi   = azapi.wan
  }

  enable_module_telemetry = try(var.virtual_wan.enable_module_telemetry, true)

  name                = var.virtual_wan.name
  location            = var.virtual_wan.location
  resource_group_name = local.rg[var.virtual_wan.resource_group_key].name

  sku = local.virtual_wan_sku

  allow_branch_to_branch_traffic = try(var.virtual_wan.allow_branch_to_branch_traffic, true)
  disable_vpn_encryption         = try(var.virtual_wan.disable_vpn_encryption, false)

  tags = local.virtual_wan_tags
}

data "azurerm_virtual_wan" "existing" {
  count = var.existing_virtual_wan == null ? 0 : 1

  provider = azurerm.wan

  name                = var.existing_virtual_wan.name
  resource_group_name = var.existing_virtual_wan.resource_group_name
}

locals {
  virtual_wan_id = var.virtual_wan != null ? module.virtual_wan[0].id : data.azurerm_virtual_wan.existing[0].id
}

module "firewall_policies" {
  for_each = var.firewall_policies

  source = "./modules/fwpolicy"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = local.rg[each.value.resource_group_key].name

  tags = merge(
    local.rg[each.value.resource_group_key].tags,
    try(each.value.tags, {})
  )

  # Optional: built-in rule sets (opt-in) + fully custom rule collection groups for this policy.
  builtins               = try(each.value.builtins, {})
  rule_collection_groups = try(each.value.rule_collection_groups, {})
}

module "expressroute_circuits" {
  for_each = var.expressroute_circuits

  source = "./modules/expressroute_circuit"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg[each.value.resource_group_key].location)
  resource_group_name = local.rg[each.value.resource_group_key].name

  sku = each.value.sku

  service_provider_name = try(each.value.service_provider_name, null)
  peering_location      = try(each.value.peering_location, null)
  bandwidth_in_mbps     = try(each.value.bandwidth_in_mbps, null)

  express_route_port_resource_id = try(each.value.express_route_port_resource_id, null)
  bandwidth_in_gbps              = try(each.value.bandwidth_in_gbps, null)

  allow_classic_operations = try(each.value.allow_classic_operations, false)
  authorization_key        = try(each.value.authorization_key, null)

  tags = merge(
    local.rg[each.value.resource_group_key].tags,
    try(each.value.tags, {})
  )

  exr_circuit_tags = try(each.value.exr_circuit_tags, null)

  peerings                             = try(each.value.peerings, {})
  express_route_circuit_authorizations = try(each.value.express_route_circuit_authorizations, {})
  er_gw_connections                    = try(each.value.er_gw_connections, {})
  vnet_gw_connections                  = try(each.value.vnet_gw_connections, {})
  circuit_connections                  = try(each.value.circuit_connections, {})
  diagnostic_settings                  = try(each.value.diagnostic_settings, {})
  role_assignments                     = try(each.value.role_assignments, {})
  lock                                 = try(each.value.lock, null)
  enable_telemetry                     = try(each.value.enable_telemetry, true)
}

data "azurerm_firewall_policy" "existing" {
  for_each = var.existing_firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

locals {
  firewall_policy_ids = merge(
    { for policy_key, policy_mod in module.firewall_policies : policy_key => policy_mod.id },
    { for policy_key, policy_data in data.azurerm_firewall_policy.existing : policy_key => policy_data.id }
  )
}

module "virtual_hubs" {
  for_each = var.virtual_hubs

  source = "./modules/vhub"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = local.rg[each.value.resource_group_key].name
  address_prefix      = each.value.address_prefix

  virtual_wan_id = local.virtual_wan_id

  tags = merge(
    local.rg[each.value.resource_group_key].tags,
    try(each.value.tags, {})
  )

  create_firewall   = try(each.value.firewall, null) != null
  firewall_name     = try(each.value.firewall.name, null)
  firewall_sku_tier = coalesce(try(each.value.firewall.sku_tier, null), "Standard")
  firewall_policy_id = coalesce(
    try(each.value.firewall.firewall_policy_id, null),
    try(local.firewall_policy_ids[each.value.firewall.firewall_policy_key], null)
  )
  firewall_extra_tags = try(each.value.firewall.tags, {})
}

module "expressroute_gateways" {
  for_each = {
    for hub_key, hub in var.virtual_hubs : hub_key => hub
    if try(hub.expressroute_gateway, null) != null
  }

  source = "./modules/expressroute_gateway"

  name = coalesce(
    try(each.value.expressroute_gateway.name, null),
    "${each.value.name}-ergw"
  )

  location            = each.value.location
  resource_group_name = local.rg[each.value.resource_group_key].name
  virtual_hub_id      = module.virtual_hubs[each.key].hub_id

  tags = merge(
    local.rg[each.value.resource_group_key].tags,
    try(each.value.tags, {}),
    try(each.value.expressroute_gateway.tags, {})
  )

  allow_non_virtual_wan_traffic = try(each.value.expressroute_gateway.allow_non_virtual_wan_traffic, false)
  scale_units                   = try(each.value.expressroute_gateway.scale_units, 1)
}

