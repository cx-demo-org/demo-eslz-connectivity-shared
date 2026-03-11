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

module "expressroute_gateway_log_analytics_workspaces" {
  for_each = var.expressroute_gateway_log_analytics_workspaces

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

locals {
  expressroute_gateway_ids_by_name = {
    for gw in coalescelist(try(module.alz_connectivity[0].express_route_gateway_resources, []), []) :
    gw.name => gw.id
  }

  expressroute_gateway_ids_by_hub_key = {
    for hub_key, hub in var.virtual_hubs :
    hub_key => lookup(local.expressroute_gateway_ids_by_name, try(hub.virtual_network_gateways.express_route.name, ""), null)
    if try(hub.enabled_resources.virtual_network_gateway_express_route, false)
    && lookup(local.expressroute_gateway_ids_by_name, try(hub.virtual_network_gateways.express_route.name, ""), null) != null
  }

  expressroute_gateway_diagnostic_settings = {
    for hub_key, ws in module.expressroute_gateway_log_analytics_workspaces : hub_key => {
      expressroute_gateway_id = local.expressroute_gateway_ids_by_hub_key[hub_key]
      workspace_id            = ws.resource_id
    }
    if contains(keys(local.expressroute_gateway_ids_by_hub_key), hub_key)
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

resource "azurerm_monitor_diagnostic_setting" "expressroute_gateway" {
  for_each = local.expressroute_gateway_diagnostic_settings

  provider = azurerm.wan

  name                       = "${each.key}-expressroutegateway-to-law"
  target_resource_id         = each.value.expressroute_gateway_id
  log_analytics_workspace_id = each.value.workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
