locals {
  # Resource group name lookup: resolve resource_group_key → resource group name
  resource_group_names = { for key, mod in module.resource_group : key => mod.name }

  # Resource group ID lookup: resolve resource_group_key → resource group resource ID
  resource_group_resource_ids = { for key, mod in module.resource_group : key => mod.resource_id }

  # Log Analytics workspace ID: use external ID if provided, otherwise use auto-created workspace
  log_analytics_workspace_resource_id = coalesce(
    try(var.byo_log_analytics_workspace.resource_id, null),
    try(module.log_analytics_workspace[0].resource_id, null)
  )

  # LAW workspace GUID: for traffic analytics workspace_id field
  law_workspace_id = (
    var.byo_log_analytics_workspace != null
    ? data.azurerm_log_analytics_workspace.external[0].workspace_id
    : try(module.log_analytics_workspace[0].resource.workspace_id, null)
  )

  # LAW region: for traffic analytics workspace_region field
  law_workspace_region = (
    var.byo_log_analytics_workspace != null
    ? var.byo_log_analytics_workspace.location
    : try(coalesce(var.log_analytics_workspace_configuration.location, var.location), var.location)
  )

  # VNet resource ID lookup: resolve vnet_key → resource ID
  vnet_resource_ids = { for key, mod in module.virtual_network : key => mod.resource_id }

  # Subnet resource ID lookup: resolve vnet_key → { subnet_key → resource ID }
  subnet_resource_ids = { for key, mod in module.virtual_network : key => { for sk, sv in mod.subnets : sk => sv.resource_id } }

  # NSG resource ID lookup: resolve NSG key → resource ID for subnet associations
  nsg_resource_ids = { for key, mod in module.network_security_group : key => mod.resource_id }

  # Route table resource ID lookup: resolve RT key → resource ID for subnet associations
  rt_resource_ids = { for key, mod in module.route_table : key => mod.resource_id }

  # Managed identity principal ID lookup: resolve MI key → principal ID for role assignments
  managed_identity_principal_ids = { for key, mod in module.managed_identity : key => mod.principal_id }

  # Storage account resource ID lookup: resolve storage account key → resource ID
  storage_account_resource_ids = { for key, mod in module.storage_account : key => mod.resource_id }

  # Private DNS zone resource ID lookup: resolve dns zone key → resource ID
  private_dns_zone_resource_ids = { for key, mod in module.private_dns_zone : key => mod.resource_id }

  # Merged DNS zone ID lookup for PE resolution: pattern-managed zones + BYO zone links
  # PEs reference these via private_dns_zone.keys — keys can come from either source
  pe_dns_zone_ids = merge(
    { for key, mod in module.private_dns_zone : key => mod.resource_id },
    { for key, link in var.byo_private_dns_zone_links : key => link.private_dns_zone_id }
  )

  # vHub connection VNet ID resolution: resolve virtual_network.key → resource ID, or pass through virtual_network.resource_id
  vhub_vnet_resource_ids = {
    for k, v in var.vhub_connectivity_definitions : k => (
      v.virtual_network.key != null
      ? local.vnet_resource_ids[v.virtual_network.key]
      : v.virtual_network.resource_id
    )
  }

  # vHub ID resolution: prefer explicit resource_id, otherwise resolve via vhub_key using virtual_hub_ids
  vhub_resource_ids = {
    for k, v in var.vhub_connectivity_definitions : k => coalesce(
      try(v.vhub_resource_id, null),
      try(var.virtual_hub_ids[v.vhub_key], null)
    )
  }
}