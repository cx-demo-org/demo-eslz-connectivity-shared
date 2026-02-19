output "resolver_id" {
  description = "Private DNS Resolver resource ID."
  value       = module.dns_resolver.resource_id
}

output "sidecar_virtual_network_id" {
  description = "Sidecar VNet resource ID."
  value       = module.sidecar_virtual_network.resource_id
}

output "sidecar_virtual_hub_connection_id" {
  description = "Virtual Hub Connection id if created, otherwise null."
  value       = try(module.sidecar_virtual_hub_connection.resource_object["sidecar"].id, null)
}

output "inbound_endpoint_ips" {
  description = "Map of inbound endpoint IP addresses by inbound endpoint key."
  value       = module.dns_resolver.inbound_endpoint_ips
}

output "outbound_endpoint_ids" {
  description = "Map of outbound endpoint IDs by outbound endpoint key."
  value = {
    for key, ep in try(module.dns_resolver.outbound_endpoints, {}) : key => try(ep.id, null)
  }
}

output "forwarding_ruleset_ids" {
  description = "Map of forwarding ruleset IDs by key."
  value = {
    for key, rs in try(module.dns_resolver.forwarding_rulesets, {}) : key => try(rs.id, null)
  }
}
