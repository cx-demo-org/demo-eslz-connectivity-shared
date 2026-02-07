module "this" {
  source  = "Azure/avm-res-network-expressroutecircuit/azurerm"
  version = "0.3.3"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = var.sku

  tags             = var.tags
  exr_circuit_tags = var.exr_circuit_tags

  allow_classic_operations       = var.allow_classic_operations
  authorization_key              = var.authorization_key
  express_route_port_resource_id = var.express_route_port_resource_id

  service_provider_name = var.service_provider_name
  peering_location      = var.peering_location
  bandwidth_in_mbps     = var.bandwidth_in_mbps
  bandwidth_in_gbps     = var.bandwidth_in_gbps

  peerings                             = var.peerings
  express_route_circuit_authorizations = var.express_route_circuit_authorizations
  er_gw_connections                    = var.er_gw_connections
  vnet_gw_connections                  = var.vnet_gw_connections
  circuit_connections                  = var.circuit_connections

  diagnostic_settings = var.diagnostic_settings
  role_assignments    = var.role_assignments
  lock                = var.lock

  enable_telemetry = var.enable_telemetry
}
