module "firewall_log_analytics_workspaces" {
  for_each = var.firewall_log_analytics_workspaces

  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg[each.value.resource_group_key].location)
  resource_group_name = local.rg[each.value.resource_group_key].name

  tags = merge(local.rg[each.value.resource_group_key].tags, try(each.value.tags, {}))

  enable_telemetry = var.enable_telemetry
}

locals {
  firewall_diagnostic_settings = {
    for hub_key, ws in module.firewall_log_analytics_workspaces : hub_key => {
      firewall_id  = local.virtual_hub_firewall_ids[hub_key]
      workspace_id = ws.resource_id
    }
    if contains(keys(local.virtual_hub_firewall_ids), hub_key)
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = local.firewall_diagnostic_settings

  provider = azurerm.wan

  name                       = "${each.key}-azurefirewall-to-law"
  target_resource_id         = each.value.firewall_id
  log_analytics_workspace_id = each.value.workspace_id

  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
