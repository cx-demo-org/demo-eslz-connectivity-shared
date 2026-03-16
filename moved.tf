moved {
  from = module.alz_connectivity[0]
  to   = module.alz_connectivity
}

moved {
  from = module.virtual_wan[0].module.this.azurerm_virtual_wan.virtual_wan
  to   = module.alz_connectivity.module.virtual_wan[0].azurerm_virtual_wan.virtual_wan
}

moved {
  from = module.virtual_hubs["prod"].module.hub.azurerm_virtual_hub.virtual_hub["hub"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_hubs.azurerm_virtual_hub.virtual_hub["prod"]
}

moved {
  from = module.virtual_hubs["prod"].module.firewall[0].azurerm_firewall.this
  to   = module.alz_connectivity.module.virtual_wan[0].module.firewalls.azurerm_firewall.fw["prod"]
}

moved {
  from = module.virtual_hubs["prod_eu"].module.hub.azurerm_virtual_hub.virtual_hub["hub"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_hubs.azurerm_virtual_hub.virtual_hub["prod_eu"]
}

moved {
  from = module.virtual_hubs["prod_eu"].module.firewall[0].azurerm_firewall.this
  to   = module.alz_connectivity.module.virtual_wan[0].module.firewalls.azurerm_firewall.fw["prod_eu"]
}

# Migrate legacy standalone modules into the AVM root module addresses.

# ExpressRoute circuits (wrapper removal)
moved {
  from = module.expressroute_circuits["prod_primary"].module.this.azurerm_express_route_circuit.this
  to   = module.expressroute_circuits["prod_primary"].azurerm_express_route_circuit.this
}

# Firewall policies (wrapper removal)
moved {
  from = module.firewall_policies["prod"].module.firewall_policy.azurerm_firewall_policy.this
  to   = module.firewall_policies["prod"].azurerm_firewall_policy.this
}

moved {
  from = module.firewall_policies["prod_eu"].module.firewall_policy.azurerm_firewall_policy.this
  to   = module.firewall_policies["prod_eu"].azurerm_firewall_policy.this
}

# Firewall policy rule collection groups (wrapper removal)
moved {
  from = module.firewall_policies["prod"].module.rule_collection_groups["aks-egress"]
  to   = module.firewall_policy_rule_collection_groups["prod/aks-egress"]
}

moved {
  from = module.firewall_policies["prod_eu"].module.rule_collection_groups["aks-egress"]
  to   = module.firewall_policy_rule_collection_groups["prod_eu/aks-egress"]
}

# Network Security Groups (migrate from raw resources to AVM module)
moved {
  from = azurerm_network_security_group.nsg["prod_sea_dns_inbound"]
  to   = module.network_security_groups["prod_sea_dns_inbound"].azurerm_network_security_group.this
}

moved {
  from = azurerm_network_security_group.nsg["prod_sea_dns_outbound"]
  to   = module.network_security_groups["prod_sea_dns_outbound"].azurerm_network_security_group.this
}

moved {
  from = azurerm_network_security_group.nsg["prod_eu_dns_inbound"]
  to   = module.network_security_groups["prod_eu_dns_inbound"].azurerm_network_security_group.this
}

moved {
  from = azurerm_network_security_group.nsg["prod_eu_dns_outbound"]
  to   = module.network_security_groups["prod_eu_dns_outbound"].azurerm_network_security_group.this
}

# ExpressRoute gateways
moved {
  from = module.expressroute_gateways["prod"].module.this.azurerm_express_route_gateway.express_route_gateway["gateway"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.express_route_gateways.azurerm_express_route_gateway.express_route_gateway["prod"]
}

moved {
  from = module.expressroute_gateways["prod_eu"].module.this.azurerm_express_route_gateway.express_route_gateway["gateway"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.express_route_gateways.azurerm_express_route_gateway.express_route_gateway["prod_eu"]
}

# Site-to-site VPN gateway and site
moved {
  from = module.site_to_site_vpns["prod"].module.vpn_gateways.azurerm_vpn_gateway.vpn_gateway["prod"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.vpn_gateway.azurerm_vpn_gateway.vpn_gateway["prod"]
}

moved {
  from = module.site_to_site_vpns["prod"].module.vpn_sites.azurerm_vpn_site.vpn_site["prod"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.vpn_site.azurerm_vpn_site.vpn_site["prod-prod"]
}

# Private DNS resolver + sidecar network (SEA)
moved {
  from = module.private_dns_resolvers["prod"].module.sidecar_virtual_network.azapi_resource.vnet
  to   = module.alz_connectivity.module.virtual_network_side_car["prod"].azapi_resource.vnet
}

moved {
  from = module.private_dns_resolvers["prod"].module.sidecar_virtual_network.module.subnet["inbound"].azapi_resource.subnet[0]
  to   = module.alz_connectivity.module.virtual_network_side_car["prod"].module.subnet["dns_resolver"].azapi_resource.subnet
}

moved {
  from = module.private_dns_resolvers["prod"].module.sidecar_virtual_network.module.subnet["outbound"].azapi_resource.subnet[0]
  to   = module.alz_connectivity.module.virtual_network_side_car["prod"].module.subnet["outbound"].azapi_resource.subnet
}

moved {
  from = module.private_dns_resolvers["prod"].module.sidecar_virtual_hub_connection.azurerm_virtual_hub_connection.hub_connection["sidecar"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_network_connections.azurerm_virtual_hub_connection.hub_connection["private_dns_vnet_prod"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver.this
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver.this
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver_inbound_endpoint.this["default"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver_inbound_endpoint.this["default"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver_outbound_endpoint.this["default"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver_outbound_endpoint.this["default"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver_dns_forwarding_ruleset.this["default-ruleset-default-default"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver_dns_forwarding_ruleset.this["default-ruleset-default-default"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver_forwarding_rule.this["default-ruleset-default-default-corp"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver_forwarding_rule.this["default-ruleset-default-default-corp"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.azurerm_private_dns_resolver_virtual_network_link.default["default-ruleset-default-default"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].azurerm_private_dns_resolver_virtual_network_link.default["default-ruleset-default-default"]
}

moved {
  from = module.private_dns_resolvers["prod"].module.dns_resolver.terraform_data.outbound["default-ruleset-default-default"]
  to   = module.alz_connectivity.module.dns_resolver["prod"].terraform_data.outbound["default-ruleset-default-default"]
}

# Private DNS resolver + sidecar network (EU)
moved {
  from = module.private_dns_resolvers["prod_eu"].module.sidecar_virtual_network.azapi_resource.vnet
  to   = module.alz_connectivity.module.virtual_network_side_car["prod_eu"].azapi_resource.vnet
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.sidecar_virtual_network.module.subnet["inbound"].azapi_resource.subnet[0]
  to   = module.alz_connectivity.module.virtual_network_side_car["prod_eu"].module.subnet["dns_resolver"].azapi_resource.subnet
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.sidecar_virtual_network.module.subnet["outbound"].azapi_resource.subnet[0]
  to   = module.alz_connectivity.module.virtual_network_side_car["prod_eu"].module.subnet["outbound"].azapi_resource.subnet
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.sidecar_virtual_hub_connection.azurerm_virtual_hub_connection.hub_connection["sidecar"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_network_connections.azurerm_virtual_hub_connection.hub_connection["private_dns_vnet_prod_eu"]
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.dns_resolver.azurerm_private_dns_resolver.this
  to   = module.alz_connectivity.module.dns_resolver["prod_eu"].azurerm_private_dns_resolver.this
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.dns_resolver.azurerm_private_dns_resolver_inbound_endpoint.this["default"]
  to   = module.alz_connectivity.module.dns_resolver["prod_eu"].azurerm_private_dns_resolver_inbound_endpoint.this["default"]
}

moved {
  from = module.private_dns_resolvers["prod_eu"].module.dns_resolver.azurerm_private_dns_resolver_outbound_endpoint.this["default"]
  to   = module.alz_connectivity.module.dns_resolver["prod_eu"].azurerm_private_dns_resolver_outbound_endpoint.this["default"]
}

