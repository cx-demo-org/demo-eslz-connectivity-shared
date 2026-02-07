output "virtual_wan_id" {
  description = "Virtual WAN resource ID (created or looked up)."
  value       = local.virtual_wan_id
}

output "firewall_policy_ids" {
  description = "Map of firewall policy ids by key (created or looked up)."
  value       = local.firewall_policy_ids
}

output "virtual_hub_ids" {
  description = "Map of virtual hub ids by key."
  value       = { for hub_key, hub_mod in module.virtual_hubs : hub_key => hub_mod.hub_id }
}

output "virtual_hub_firewall_ids" {
  description = "Map of firewall ids by virtual hub key (null if not created)."
  value       = { for hub_key, hub_mod in module.virtual_hubs : hub_key => hub_mod.firewall_id }
}

output "expressroute_gateway_ids" {
  description = "Map of ExpressRoute Gateway ids by virtual hub key (only for hubs with expressroute_gateway configured)."
  value       = { for hub_key, gw_mod in module.expressroute_gateways : hub_key => gw_mod.id }
}

output "expressroute_circuit_ids" {
  description = "Map of ExpressRoute Circuit resource IDs by key."
  value       = { for circuit_key, circuit_mod in module.expressroute_circuits : circuit_key => circuit_mod.resource_id }
}

