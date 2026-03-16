module "expressroute_circuits" {
  for_each = var.expressroute_circuits

  source  = "Azure/avm-res-network-expressroutecircuit/azurerm"
  version = "0.3.3"

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
