module "connectivity" {
  source = "./modules/connectivity"

  providers = {
    azurerm     = azurerm
    azurerm.wan = azurerm.wan
    azapi       = azapi
    azapi.wan   = azapi.wan
  }

  resource_groups          = var.resource_groups
  existing_resource_groups = var.existing_resource_groups

  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  default_naming_convention          = var.default_naming_convention
  default_naming_convention_sequence = var.default_naming_convention_sequence
  retry                              = var.retry
  timeouts                           = var.timeouts

  private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix = var.private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix

  virtual_wan_settings = var.virtual_wan_settings
  virtual_hubs         = var.virtual_hubs

  firewall_policies          = var.firewall_policies
  existing_firewall_policies = var.existing_firewall_policies

  network_security_groups          = var.network_security_groups
  existing_network_security_groups = var.existing_network_security_groups

  expressroute_circuits = var.expressroute_circuits

  firewall_log_analytics_workspaces             = var.firewall_log_analytics_workspaces
  expressroute_gateway_log_analytics_workspaces = var.expressroute_gateway_log_analytics_workspaces

  role_assignments_azure_resource_manager = var.role_assignments_azure_resource_manager

  firewall_diagnostic_log_analytics_destination_type = var.firewall_diagnostic_log_analytics_destination_type
  firewall_diagnostic_enabled_log_category_group     = var.firewall_diagnostic_enabled_log_category_group
  firewall_diagnostic_enabled_metric_category        = var.firewall_diagnostic_enabled_metric_category
  firewall_diagnostic_enabled_metric_enabled         = var.firewall_diagnostic_enabled_metric_enabled

  expressroute_gateway_diagnostic_enabled_metric_category = var.expressroute_gateway_diagnostic_enabled_metric_category
  expressroute_gateway_diagnostic_enabled_metric_enabled  = var.expressroute_gateway_diagnostic_enabled_metric_enabled
}

module "dmz_vnet" {
  count  = var.dmz_vnet == null ? 0 : 1
  source = "./modules/dmz_vnet"

  location = try(var.dmz_vnet.location, null)
  tags     = try(var.dmz_vnet.tags, {})
  lock     = try(var.dmz_vnet.lock, null)

  resource_groups = try(var.dmz_vnet.resource_groups, {})

  byo_log_analytics_workspace           = try(var.dmz_vnet.byo_log_analytics_workspace, null)
  log_analytics_workspace_configuration = try(var.dmz_vnet.log_analytics_workspace_configuration, null)

  network_security_groups = try(var.dmz_vnet.network_security_groups, {})
  route_tables            = try(var.dmz_vnet.route_tables, {})
  virtual_networks        = try(var.dmz_vnet.virtual_networks, {})

  # Optional extras (keep pass-through defaults in the dmz_vnet module)
  private_dns_zones             = try(var.dmz_vnet.private_dns_zones, {})
  byo_private_dns_zone_links    = try(var.dmz_vnet.byo_private_dns_zone_links, {})
  managed_identities            = try(var.dmz_vnet.managed_identities, {})
  key_vaults                    = try(var.dmz_vnet.key_vaults, {})
  storage_accounts              = try(var.dmz_vnet.storage_accounts, {})
  role_assignments              = try(var.dmz_vnet.role_assignments, {})
  vhub_connectivity_definitions = try(var.dmz_vnet.vhub_connectivity_definitions, {})
  bastion_hosts                 = try(var.dmz_vnet.bastion_hosts, {})
  flowlog_configuration         = try(var.dmz_vnet.flowlog_configuration, null)

  # Enables vHub connection definitions to use vhub_key instead of hard-coded resource IDs.
  virtual_hub_ids = module.connectivity.virtual_hub_ids
}

module "dmz_application_gw" {
  count  = (var.dmz_vnet == null || (length(var.dmz_application_gateways) == 0 && length(var.dmz_web_application_firewall_policies) == 0)) ? 0 : 1
  source = "./modules/application_gw"

  resource_groups  = module.dmz_vnet[0].resource_groups
  virtual_networks = module.dmz_vnet[0].virtual_networks

  web_application_firewall_policies = var.dmz_web_application_firewall_policies
  application_gateways              = var.dmz_application_gateways
  enable_telemetry                  = var.enable_telemetry
}

