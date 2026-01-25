output "firewall_policy_id" {
  description = "Resource ID of the Azure Firewall Policy."
  value       = azurerm_firewall_policy.this.id
}
