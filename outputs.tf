output "virtual_wan_id" {
  description = "Virtual WAN resource ID."
  value       = module.connectivity.virtual_wan_id
}

output "firewall_policy_ids" {
  description = "Map of firewall policy ids by key (created or looked up)."
  value       = module.connectivity.firewall_policy_ids
}

output "virtual_hub_ids" {
  description = "Map of virtual hub ids by key."
  value       = module.connectivity.virtual_hub_ids
}

output "virtual_hub_firewall_ids" {
  description = "Map of firewall ids by virtual hub key (null if not created)."
  value       = module.connectivity.virtual_hub_firewall_ids
}

output "expressroute_gateway_ids" {
  description = "Map of ExpressRoute Gateway ids by virtual hub key (only for hubs with expressroute_gateway configured)."
  value       = module.connectivity.expressroute_gateway_ids
}

output "expressroute_circuit_ids" {
  description = "Map of ExpressRoute Circuit resource IDs by key."
  value       = module.connectivity.expressroute_circuit_ids
}

output "private_dns_resolver_ids" {
  description = "Map of Private DNS Resolver IDs by virtual hub key (only for hubs with private_dns_resolver configured)."
  value       = module.connectivity.private_dns_resolver_ids
}

output "private_dns_resolver_inbound_endpoint_ips" {
  description = "Map of inbound endpoint IPs by virtual hub key (and inbound endpoint key)."
  value       = module.connectivity.private_dns_resolver_inbound_endpoint_ips
}

output "private_dns_resolver_sidecar_vnet_ids" {
  description = "Map of sidecar VNet IDs by virtual hub key (only for hubs with private_dns_resolver configured)."
  value       = module.connectivity.private_dns_resolver_sidecar_vnet_ids
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

output "dmz_virtual_networks" {
  description = "(Optional) DMZ VNets created by modules/dmz_vnet (null when disabled)."
  value       = length(module.dmz_vnet) > 0 ? module.dmz_vnet[0].virtual_networks : null
}

output "dmz_web_application_firewall_policy_ids" {
  description = "(Optional) DMZ WAF policy IDs by key (empty when disabled)."
  value       = length(module.dmz_application_gw) > 0 ? module.dmz_application_gw[0].web_application_firewall_policy_ids : {}
}

output "dmz_application_gateway_ids" {
  description = "(Optional) DMZ Application Gateway IDs by key (empty when disabled)."
  value       = length(module.dmz_application_gw) > 0 ? module.dmz_application_gw[0].application_gateway_ids : {}
}

output "dmz_application_gateway_public_ip_ids" {
  description = "(Optional) DMZ Application Gateway public IP resource IDs by key (empty when disabled)."
  value       = length(module.dmz_application_gw) > 0 ? module.dmz_application_gw[0].application_gateway_public_ip_ids : {}
}

output "dmz_application_gateway_public_ip_addresses" {
  description = "(Optional) DMZ Application Gateway public IP addresses by key (empty when disabled)."
  value       = length(module.dmz_application_gw) > 0 ? module.dmz_application_gw[0].application_gateway_public_ip_addresses : {}
}

