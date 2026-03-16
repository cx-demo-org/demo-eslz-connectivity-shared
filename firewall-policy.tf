module "firewall_policies" {
  for_each = var.firewall_policies

  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))

  firewall_policy_sku = try(each.value.firewall_policy_sku, "Standard")
  enable_telemetry    = try(each.value.enable_telemetry, false)
}

module "firewall_policy_rule_collection_groups" {
  for_each = merge([
    for policy_key, policy in var.firewall_policies : {
      for rcg_key, rcg in try(policy.rule_collection_groups, {}) :
      "${policy_key}/${rcg_key}" => {
        policy_key                  = policy_key
        rule_collection_group_name  = rcg_key
        priority                    = rcg.priority
        application_rule_collection = try(rcg.application_rule_collection, null)
        network_rule_collection     = try(rcg.network_rule_collection, null)
        nat_rule_collection         = try(rcg.nat_rule_collection, null)
      }
    }
  ]...)

  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.4"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policies[each.value.policy_key].resource_id
  firewall_policy_rule_collection_group_name               = each.value.rule_collection_group_name
  firewall_policy_rule_collection_group_priority           = each.value.priority

  firewall_policy_rule_collection_group_application_rule_collection = each.value.application_rule_collection
  firewall_policy_rule_collection_group_network_rule_collection     = each.value.network_rule_collection
  firewall_policy_rule_collection_group_nat_rule_collection         = each.value.nat_rule_collection
}

data "azurerm_firewall_policy" "existing" {
  for_each = var.existing_firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}
