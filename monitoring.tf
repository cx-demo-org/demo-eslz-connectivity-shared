module "firewall_log_analytics_workspaces" {
  for_each = var.firewall_log_analytics_workspaces

  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), try(module.resource_groups[each.value.resource_group_key].location, data.azurerm_resource_group.rg[each.value.resource_group_key].location))
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))

  enable_telemetry = var.enable_telemetry
}

module "expressroute_gateway_log_analytics_workspaces" {
  for_each = var.expressroute_gateway_log_analytics_workspaces

  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), try(module.resource_groups[each.value.resource_group_key].location, data.azurerm_resource_group.rg[each.value.resource_group_key].location))
  resource_group_name = try(module.resource_groups[each.value.resource_group_key].name, data.azurerm_resource_group.rg[each.value.resource_group_key].name)

  tags = merge(try(module.resource_groups[each.value.resource_group_key].resource.tags, data.azurerm_resource_group.rg[each.value.resource_group_key].tags, {}), try(each.value.tags, {}))

  enable_telemetry = var.enable_telemetry
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = {
    for hub_key, ws in module.firewall_log_analytics_workspaces : hub_key => {
      firewall_id  = module.alz_connectivity.firewall_resource_ids[hub_key]
      workspace_id = ws.resource_id
    }
    if contains(keys(module.alz_connectivity.firewall_resource_ids), hub_key)
  }

  provider = azurerm.wan

  name                       = "${each.key}-azurefirewall-to-law"
  target_resource_id         = each.value.firewall_id
  log_analytics_workspace_id = each.value.workspace_id

  log_analytics_destination_type = var.firewall_diagnostic_log_analytics_destination_type

  enabled_log {
    category_group = var.firewall_diagnostic_enabled_log_category_group
  }

  dynamic "enabled_metric" {
    for_each = var.firewall_diagnostic_enabled_metric_enabled ? [1] : []
    content {
      category = var.firewall_diagnostic_enabled_metric_category
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "expressroute_gateway" {
  for_each = {
    for hub_key, ws in module.expressroute_gateway_log_analytics_workspaces : hub_key => {
      expressroute_gateway_id = lookup({ for gw in coalescelist(try(module.alz_connectivity.express_route_gateway_resources, []), []) : gw.name => gw.id }, try(var.virtual_hubs[hub_key].virtual_network_gateways.express_route.name, ""), null)
      workspace_id            = ws.resource_id
    }
    if contains(keys(var.virtual_hubs), hub_key)
    && try(var.virtual_hubs[hub_key].enabled_resources.virtual_network_gateway_express_route, false)
    && try(var.virtual_hubs[hub_key].virtual_network_gateways.express_route.name, "") != ""
  }

  provider = azurerm.wan

  name                       = "${each.key}-expressroutegateway-to-law"
  target_resource_id         = each.value.expressroute_gateway_id
  log_analytics_workspace_id = each.value.workspace_id

  dynamic "enabled_metric" {
    for_each = var.expressroute_gateway_diagnostic_enabled_metric_enabled ? [1] : []
    content {
      category = var.expressroute_gateway_diagnostic_enabled_metric_category
    }
  }
}
