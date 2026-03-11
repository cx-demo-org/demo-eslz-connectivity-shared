module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  firewall_policy_sku = var.firewall_policy_sku
  tags                = var.tags

  enable_telemetry = var.enable_telemetry
}

module "rule_collection_groups" {
  for_each = var.rule_collection_groups

  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.4"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource_id
  firewall_policy_rule_collection_group_name               = each.key
  firewall_policy_rule_collection_group_priority           = each.value.priority

  firewall_policy_rule_collection_group_application_rule_collection = try(each.value.application_rule_collection, null)
  firewall_policy_rule_collection_group_network_rule_collection     = try(each.value.network_rule_collection, null)
  firewall_policy_rule_collection_group_nat_rule_collection         = try(each.value.nat_rule_collection, null)
}

moved {
  from = azurerm_firewall_policy.this
  to   = module.firewall_policy.azurerm_firewall_policy.this
}

