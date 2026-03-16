output "virtual_wan_id" {
  description = "Virtual WAN resource ID."
  value       = module.alz_connectivity.resource_id
}

output "firewall_policy_ids" {
  description = "Map of firewall policy ids by key (created or looked up)."
  value = merge(
    { for policy_key, policy_mod in module.firewall_policies : policy_key => policy_mod.resource_id },
    { for policy_key, policy_data in data.azurerm_firewall_policy.existing : policy_key => policy_data.id }
  )
}

output "virtual_hub_ids" {
  description = "Map of virtual hub ids by key."
  value       = module.alz_connectivity.virtual_hub_resource_ids
}

output "virtual_hub_firewall_ids" {
  description = "Map of firewall ids by virtual hub key (null if not created)."
  value       = module.alz_connectivity.firewall_resource_ids
}

output "expressroute_gateway_ids" {
  description = "Map of ExpressRoute Gateway ids by virtual hub key (only for hubs with expressroute_gateway configured)."
  value = {
    for hub_key, hub_id in module.alz_connectivity.virtual_hub_resource_ids :
    hub_key => try([
      for gw in try(module.alz_connectivity.express_route_gateway_resources, []) : gw.id
      if gw.virtual_hub_id == hub_id
    ][0], null)
    if try([
      for gw in try(module.alz_connectivity.express_route_gateway_resources, []) : gw.id
      if gw.virtual_hub_id == hub_id
    ][0], null) != null
  }
}

output "expressroute_circuit_ids" {
  description = "Map of ExpressRoute Circuit resource IDs by key."
  value       = { for circuit_key, circuit_mod in module.expressroute_circuits : circuit_key => circuit_mod.resource_id }
}

output "private_dns_resolver_ids" {
  description = "Map of Private DNS Resolver IDs by virtual hub key (only for hubs with private_dns_resolver configured)."
  value       = coalesce(try(module.alz_connectivity.private_dns_resolver_resource_ids, null), {})
}

output "private_dns_resolver_inbound_endpoint_ips" {
  description = "Map of inbound endpoint IPs by virtual hub key (and inbound endpoint key)."
  value = {
    for hub_key, pdr_mod in coalesce(try(module.alz_connectivity.private_dns_resolver_resources, null), {}) : hub_key => try(pdr_mod.inbound_endpoint_ips, {})
  }
}

output "private_dns_resolver_sidecar_vnet_ids" {
  description = "Map of sidecar VNet IDs by virtual hub key (only for hubs with private_dns_resolver configured)."
  value       = coalesce(try(module.alz_connectivity.sidecar_virtual_network_resource_ids, null), {})
}

output "site_to_site_vpn_gateway_ids" {
  description = "Map of S2S VPN Gateway IDs by virtual hub key and gateway key."
  value       = {}
}

output "site_to_site_vpn_site_ids" {
  description = "Map of VPN Site IDs by virtual hub key and site key."
  value       = {}
}

output "site_to_site_vpn_connection_ids" {
  description = "Map of VPN Site Connection IDs by virtual hub key and connection key."
  value       = {}
}

