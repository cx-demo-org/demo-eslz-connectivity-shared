output "hub_id" {
  description = "Virtual Hub resource ID."
  value       = module.hub.resource["hub"].id
}

output "firewall_id" {
  description = "Azure Firewall resource ID if created, otherwise null."
  value       = var.create_firewall ? module.firewall[0].resource_id : null
}
