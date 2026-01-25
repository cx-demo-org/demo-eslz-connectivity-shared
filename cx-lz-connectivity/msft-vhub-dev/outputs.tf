output "virtual_hub_id" {
  description = "Resource ID of the Virtual Hub."
  value       = module.connectivity_virtual_hub.resource["hub"].id
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall deployed into the hub."
  value       = azurerm_firewall.hub.id
}
