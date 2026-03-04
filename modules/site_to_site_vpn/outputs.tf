output "vpn_gateway_ids" {
  description = "Map of VPN Gateway IDs by key."
  value       = { for key, obj in module.vpn_gateways.resource_object : key => obj.id }
}

output "vpn_site_ids" {
  description = "Map of VPN Site IDs by key."
  value       = module.vpn_sites.resource_id
}

output "vpn_site_connection_ids" {
  description = "Map of VPN Site Connection IDs by key."
  value       = module.vpn_site_connections.resource_id
}

output "vpn_site_links" {
  description = "Map of VPN Site links by site key."
  value       = module.vpn_sites.links
}
