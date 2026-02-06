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
