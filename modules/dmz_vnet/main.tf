data "azurerm_client_config" "current" {}

data "azurerm_log_analytics_workspace" "external" {
  count = var.byo_log_analytics_workspace != null ? 1 : 0

  name                = split("/", var.byo_log_analytics_workspace.resource_id)[8]
  resource_group_name = split("/", var.byo_log_analytics_workspace.resource_id)[4]
}

# ──────────────────────────────────────────────────────────────
# Cross-variable validation (preconditions on terraform_data)
# ──────────────────────────────────────────────────────────────

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = var.byo_log_analytics_workspace != null || var.log_analytics_workspace_configuration != null
      error_message = "log_analytics_workspace_configuration must be provided when byo_log_analytics_workspace is null, so that a Log Analytics workspace can be auto-created."
    }

    precondition {
      condition = alltrue([
        for k, link in var.byo_private_dns_zone_links :
        contains(keys(var.virtual_networks), link.virtual_network_key)
      ])
      error_message = "DNS zone link references a virtual_network_key that does not exist in virtual_networks."
    }

    precondition {
      condition = alltrue([
        for kv_key, kv in var.key_vaults : alltrue([
          for ra_key, ra in kv.role_assignments :
          ra.managed_identity_key == null || contains(keys(var.managed_identities), ra.managed_identity_key)
        ])
      ])
      error_message = "Key Vault role assignment references a managed_identity_key that does not exist in managed_identities."
    }

    precondition {
      condition = alltrue([
        for ra_key, ra in var.role_assignments :
        ra.managed_identity_key == null || contains(keys(var.managed_identities), ra.managed_identity_key)
      ])
      error_message = "Standalone role assignment references a managed_identity_key that does not exist in managed_identities."
    }

    precondition {
      condition = alltrue([
        for fl_key, fl in try(var.flowlog_configuration.flow_logs, {}) :
        (fl.storage_account.resource_id != null) != (fl.storage_account.key != null)
      ])
      error_message = "Each flow log must set exactly one of storage_account.resource_id or storage_account.key."
    }

    precondition {
      condition = alltrue([
        for fl_key, fl in try(var.flowlog_configuration.flow_logs, {}) :
        fl.storage_account.key == null || contains(keys(var.storage_accounts), fl.storage_account.key)
      ])
      error_message = "Flow log references a storage_account.key that does not exist in storage_accounts."
    }

    precondition {
      condition = alltrue([
        for fl_key, fl in try(var.flowlog_configuration.flow_logs, {}) :
        contains(keys(var.virtual_networks), fl.vnet_key)
      ])
      error_message = "Flow log references a vnet_key that does not exist in virtual_networks."
    }
  }
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  for_each = var.resource_groups

  name             = each.value.name
  location         = coalesce(each.value.location, var.location)
  tags             = merge(var.tags, each.value.tags)
  lock             = each.value.lock != null ? each.value.lock : var.lock
  role_assignments = each.value.role_assignments
}

module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  count = var.byo_log_analytics_workspace == null ? 1 : 0

  name                                      = var.log_analytics_workspace_configuration.name
  location                                  = coalesce(var.log_analytics_workspace_configuration.location, var.location)
  resource_group_name                       = local.resource_group_names[var.log_analytics_workspace_configuration.resource_group_key]
  log_analytics_workspace_sku               = var.log_analytics_workspace_configuration.sku
  log_analytics_workspace_retention_in_days = var.log_analytics_workspace_configuration.retention_in_days
  tags                                      = merge(var.tags, var.log_analytics_workspace_configuration.tags)
  lock                                      = var.lock
  role_assignments                          = var.log_analytics_workspace_configuration.role_assignments

  private_endpoints = {
    for pe_k, pe in var.log_analytics_workspace_configuration.private_endpoints : pe_k => {
      name = pe.name
      tags = pe.tags
      subnet_resource_id = coalesce(
        pe.network_configuration.subnet_resource_id,
        try(local.subnet_resource_ids[pe.network_configuration.vnet_key][pe.network_configuration.subnet_key], null)
      )
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : local.pe_dns_zone_ids[k]])
      )
    }
  }
}

module "network_security_group" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  security_rules      = each.value.security_rules
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = coalesce(dv.workspace_resource_id, local.log_analytics_workspace_resource_id)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
  lock             = var.lock
  tags             = merge(var.tags, each.value.tags)
  role_assignments = each.value.role_assignments
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  for_each = var.route_tables

  name                          = each.value.name
  resource_group_name           = local.resource_group_names[each.value.resource_group_key]
  location                      = coalesce(each.value.location, var.location)
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  lock                          = var.lock
  tags                          = merge(var.tags, each.value.tags)
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  for_each = var.virtual_networks

  name          = each.value.name
  parent_id     = local.resource_group_resource_ids[each.value.resource_group_key]
  location      = coalesce(each.value.location, var.location)
  address_space = each.value.address_space

  dns_servers = each.value.dns_servers != null ? { dns_servers = each.value.dns_servers } : null
  ddos_protection_plan = each.value.ddos_protection_plan != null ? {
    id     = each.value.ddos_protection_plan.resource_id
    enable = each.value.ddos_protection_plan.enable
  } : null
  encryption = each.value.encryption

  subnets = {
    for sk, sv in each.value.subnets : sk => merge(sv, {
      network_security_group = sv.network_security_group_key != null ? {
        id = local.nsg_resource_ids[sv.network_security_group_key]
      } : null
      route_table = sv.route_table_key != null ? {
        id = local.rt_resource_ids[sv.route_table_key]
      } : null
    })
  }

  peerings = each.value.peerings
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = coalesce(dv.workspace_resource_id, local.log_analytics_workspace_resource_id)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
  lock             = var.lock
  tags             = merge(var.tags, each.value.tags)
  role_assignments = each.value.role_assignments
}

module "private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  for_each = var.private_dns_zones

  domain_name = each.value.domain_name
  parent_id   = local.resource_group_resource_ids[each.value.resource_group_key]
  virtual_network_links = {
    for vnl_k, vnl in each.value.virtual_network_links : vnl_k => {
      name                 = vnl.name
      virtual_network_id   = local.vnet_resource_ids[vnl.virtual_network_key]
      registration_enabled = vnl.registration_enabled
      resolution_policy    = vnl.resolution_policy
      tags                 = merge(var.tags, vnl.tags)
    }
  }
  lock = var.lock
  tags = merge(var.tags, each.value.tags)
}

module "private_dns_zone_link" {
  source  = "Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link"
  version = "0.5.0"

  for_each = var.byo_private_dns_zone_links

  name                 = each.value.name
  parent_id            = each.value.private_dns_zone_id
  virtual_network_id   = local.vnet_resource_ids[each.value.virtual_network_key]
  registration_enabled = each.value.registration_enabled
  resolution_policy    = each.value.resolution_policy
  tags                 = merge(var.tags, each.value.tags)
}

module "managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.4.0"

  for_each = var.managed_identities

  name                = each.value.name
  location            = coalesce(each.value.location, var.location)
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  lock                = var.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments    = each.value.role_assignments
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  for_each = var.key_vaults

  name                          = each.value.name
  location                      = coalesce(each.value.location, var.location)
  resource_group_name           = local.resource_group_names[each.value.resource_group_key]
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = each.value.sku_name
  public_network_access_enabled = each.value.public_network_access_enabled
  purge_protection_enabled      = each.value.purge_protection_enabled
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  network_acls                  = each.value.network_acls
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = coalesce(dv.workspace_resource_id, local.log_analytics_workspace_resource_id)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
  lock = var.lock
  tags = merge(var.tags, each.value.tags)

  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name = ra.role_definition_id_or_name
      principal_id               = ra.managed_identity_key != null ? local.managed_identity_principal_ids[ra.managed_identity_key] : ra.principal_id
      description                = ra.description
      principal_type             = ra.principal_type
    }
  }

  private_endpoints = {
    for pe_k, pe in each.value.private_endpoints : pe_k => {
      name = pe.name
      tags = pe.tags
      subnet_resource_id = coalesce(
        pe.network_configuration.subnet_resource_id,
        try(local.subnet_resource_ids[pe.network_configuration.vnet_key][pe.network_configuration.subnet_key], null)
      )
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : local.pe_dns_zone_ids[k]])
      )
    }
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.7"

  for_each = var.storage_accounts

  name                            = each.value.name
  resource_group_name             = local.resource_group_names[each.value.resource_group_key]
  location                        = coalesce(each.value.location, var.location)
  account_tier                    = each.value.account_tier
  account_replication_type        = each.value.account_replication_type
  account_kind                    = each.value.account_kind
  access_tier                     = each.value.access_tier
  shared_access_key_enabled       = each.value.shared_access_key_enabled
  public_network_access_enabled   = each.value.public_network_access_enabled
  https_traffic_only_enabled      = each.value.https_traffic_only_enabled
  min_tls_version                 = each.value.min_tls_version
  allow_nested_items_to_be_public = each.value.allow_nested_items_to_be_public
  network_rules                   = each.value.network_rules
  managed_identities              = each.value.managed_identities
  containers                      = each.value.containers
  role_assignments                = each.value.role_assignments
  lock                            = each.value.lock != null ? each.value.lock : var.lock
  diagnostic_settings_storage_account = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = coalesce(dv.workspace_resource_id, local.log_analytics_workspace_resource_id)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
  tags             = merge(var.tags, each.value.tags)
  enable_telemetry = false

  private_endpoints = {
    for pe_k, pe in each.value.private_endpoints : pe_k => {
      name = pe.name
      tags = pe.tags
      subnet_resource_id = coalesce(
        pe.network_configuration.subnet_resource_id,
        try(local.subnet_resource_ids[pe.network_configuration.vnet_key][pe.network_configuration.subnet_key], null)
      )
      subresource_name = pe.subresource_name
      private_dns_zone_resource_ids = setunion(
        coalesce(try(pe.private_dns_zone.resource_ids, null), toset([])),
        toset([for k in coalesce(try(pe.private_dns_zone.keys, null), toset([])) : local.pe_dns_zone_ids[k]])
      )
    }
  }
}

module "role_assignment" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"

  count = length(var.role_assignments) > 0 ? 1 : 0

  role_assignments_azure_resource_manager = {
    for ra_key, ra in var.role_assignments : ra_key => {
      role_definition_name = ra.role_definition_id_or_name
      scope                = ra.scope
      principal_id         = ra.managed_identity_key != null ? local.managed_identity_principal_ids[ra.managed_identity_key] : ra.principal_id
      description          = ra.description
      principal_type       = ra.principal_type
    }
  }
}

module "vhub_vnet_connection" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection"
  version = "0.13.5"

  for_each = var.vhub_connectivity_definitions

  virtual_network_connections = {
    (each.key) = {
      name                      = each.key
      virtual_hub_id            = local.vhub_resource_ids[each.key]
      remote_virtual_network_id = local.vhub_vnet_resource_ids[each.key]
      internet_security_enabled = each.value.internet_security_enabled
      routing                   = each.value.routing
    }
  }
}

module "bastion_host" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  for_each = var.bastion_hosts

  name      = each.value.name
  location  = coalesce(each.value.location, var.location)
  parent_id = local.resource_group_resource_ids[each.value.resource_group_key]
  sku       = each.value.sku
  zones     = each.value.zones
  ip_configuration = each.value.ip_configuration != null ? {
    name = each.value.ip_configuration.name
    subnet_id = coalesce(
      each.value.ip_configuration.network_configuration.subnet_resource_id,
      try(local.subnet_resource_ids[each.value.ip_configuration.network_configuration.vnet_key][each.value.ip_configuration.network_configuration.subnet_key], null)
    )
    create_public_ip                 = each.value.ip_configuration.create_public_ip
    public_ip_tags                   = each.value.ip_configuration.public_ip_tags
    public_ip_merge_with_module_tags = each.value.ip_configuration.public_ip_merge_with_module_tags
    public_ip_address_name           = each.value.ip_configuration.public_ip_address_name
    public_ip_address_id             = each.value.ip_configuration.public_ip_address_id
  } : null
  virtual_network_id = try(coalesce(
    try(each.value.virtual_network.resource_id, null),
    try(local.vnet_resource_ids[each.value.virtual_network.key], null)
  ), null)
  copy_paste_enabled        = each.value.copy_paste_enabled
  file_copy_enabled         = each.value.file_copy_enabled
  ip_connect_enabled        = each.value.ip_connect_enabled
  kerberos_enabled          = each.value.kerberos_enabled
  private_only_enabled      = each.value.private_only_enabled
  scale_units               = each.value.scale_units
  session_recording_enabled = each.value.session_recording_enabled
  shareable_link_enabled    = each.value.shareable_link_enabled
  tunneling_enabled         = each.value.tunneling_enabled
  diagnostic_settings = {
    for dk, dv in each.value.diagnostic_settings : dk => {
      name                                     = dv.name
      log_categories                           = dv.log_categories
      log_groups                               = dv.log_groups
      metric_categories                        = dv.metric_categories
      log_analytics_destination_type           = dv.log_analytics_destination_type
      workspace_resource_id                    = coalesce(dv.workspace_resource_id, local.log_analytics_workspace_resource_id)
      storage_account_resource_id              = dv.storage_account_resource_id
      event_hub_authorization_rule_resource_id = dv.event_hub_authorization_rule_resource_id
      event_hub_name                           = dv.event_hub_name
      marketplace_partner_resource_id          = dv.marketplace_partner_resource_id
    }
  }
  lock             = var.lock
  tags             = merge(var.tags, each.value.tags)
  role_assignments = each.value.role_assignments
}

# ──────────────────────────────────────────────────────────────
# Network Watcher – Flow Logs (C3 / FR-040)
# ──────────────────────────────────────────────────────────────

module "network_watcher" {
  source  = "Azure/avm-res-network-networkwatcher/azurerm"
  version = "0.3.2"

  count = var.flowlog_configuration != null ? 1 : 0

  network_watcher_id   = coalesce(var.flowlog_configuration.network_watcher_id, "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_${coalesce(var.flowlog_configuration.location, var.location)}")
  network_watcher_name = coalesce(var.flowlog_configuration.network_watcher_name, "NetworkWatcher_${coalesce(var.flowlog_configuration.location, var.location)}")
  resource_group_name  = coalesce(var.flowlog_configuration.resource_group_name, "NetworkWatcherRG")
  location             = coalesce(var.flowlog_configuration.location, var.location)
  flow_logs = var.flowlog_configuration.flow_logs != null ? {
    for k, fl in var.flowlog_configuration.flow_logs : k => {
      enabled            = fl.enabled
      name               = fl.name
      target_resource_id = local.vnet_resource_ids[fl.vnet_key]
      retention_policy   = fl.retention_policy
      storage_account_id = coalesce(
        fl.storage_account.resource_id,
        try(local.storage_account_resource_ids[fl.storage_account.key], null)
      )
      traffic_analytics = fl.traffic_analytics != null ? {
        enabled               = fl.traffic_analytics.enabled
        interval_in_minutes   = fl.traffic_analytics.interval_in_minutes
        workspace_id          = coalesce(fl.traffic_analytics.workspace_id, local.law_workspace_id)
        workspace_region      = coalesce(fl.traffic_analytics.workspace_region, local.law_workspace_region)
        workspace_resource_id = coalesce(fl.traffic_analytics.workspace_resource_id, local.log_analytics_workspace_resource_id)
      } : null
      version = fl.version
    }
  } : null
  lock = var.lock
  tags = merge(var.tags, var.flowlog_configuration.tags)
}