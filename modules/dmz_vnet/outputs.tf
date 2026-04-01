output "resource_groups" {
  value = { for key, mod in module.resource_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of resource group keys to their resource IDs and names."
}

output "log_analytics_workspace" {
  value = {
    resource_id = local.log_analytics_workspace_resource_id
    name        = split("/", local.log_analytics_workspace_resource_id)[length(split("/", local.log_analytics_workspace_resource_id)) - 1]
  }
  description = "Log Analytics workspace resource ID and name (auto-created or externally provided). Name is derived from the resource ID."
}

output "network_security_groups" {
  value = { for key, mod in module.network_security_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of NSG keys to their resource IDs and names."
}

output "route_tables" {
  value = { for key, mod in module.route_table : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of route table keys to their resource IDs and names."
}

output "virtual_networks" {
  value = { for key, mod in module.virtual_network : key => {
    resource_id    = mod.resource_id
    name           = mod.name
    address_spaces = mod.address_spaces
    subnets        = mod.subnets
    peerings       = mod.peerings
  } }
  description = "Map of VNet keys to their resource IDs, names, address spaces, subnet details, and peering details."
}

output "private_dns_zones" {
  value = { for key, mod in module.private_dns_zone : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of Private DNS Zone keys to their resource IDs and names. Empty map when no private_dns_zones are configured."
}

output "byo_private_dns_zone_links" {
  value = { for key, mod in module.private_dns_zone_link : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of BYO Private DNS Zone VNet link keys to their resource IDs and names."
}

output "managed_identities" {
  value = { for key, mod in module.managed_identity : key => {
    resource_id  = mod.resource_id
    name         = mod.resource_name
    principal_id = mod.principal_id
    client_id    = mod.client_id
  } }
  description = "Map of managed identity keys to their resource IDs, names, principal IDs, and client IDs."
}

output "key_vaults" {
  value = { for key, mod in module.key_vault : key => {
    resource_id = mod.resource_id
    name        = mod.name
    uri         = mod.uri
  } }
  description = "Map of Key Vault keys to their resource IDs, names, and URIs."
}

output "role_assignments" {
  value = length(var.role_assignments) > 0 ? {
    for key, ra in module.role_assignment[0].role_assignments : key => {
      resource_id = ra.role_assignment_id
    }
  } : {}
  description = "Map of standalone role assignment keys to their resource IDs. Empty map when no standalone role assignments are configured."
}

output "vhub_connections" {
  value = {
    for k, v in module.vhub_vnet_connection : k => {
      resource_id = v.resource_object[k].id
    }
  }
  description = "Map of Virtual Hub VNet connections, keyed by vhub_connectivity_definitions map key. Empty map when no vWAN connections are configured."
}

output "bastion_hosts" {
  value = {
    for k, v in module.bastion_host : k => {
      resource_id = v.resource_id
      name        = v.name
    }
  }
  description = "Map of Bastion host resource IDs and names, keyed by bastion_hosts map key. Empty map when no Bastion hosts are deployed."
}

output "network_watcher" {
  value = var.flowlog_configuration != null ? {
    resource_id = module.network_watcher[0].resource_id
    flow_logs   = module.network_watcher[0].resource_flow_log
  } : null
  description = "Network Watcher resource ID and flow log details. Null when flowlog_configuration is not provided."
}

output "storage_accounts" {
  value = { for key, mod in module.storage_account : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of storage account keys to their resource IDs and names."
}