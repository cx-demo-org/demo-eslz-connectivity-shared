locals {
  sidecar_vnet_name = coalesce(try(var.sidecar_virtual_network.name, null), "${var.name}-sidecar")

  sidecar_vnet_tags = merge(
    var.tags,
    try(var.sidecar_virtual_network.tags, {})
  )

  inbound_subnet_name  = var.inbound_subnet.name
  outbound_subnet_name = var.outbound_subnet.name

  inbound_endpoints_effective = length(var.inbound_endpoints) > 0 ? var.inbound_endpoints : {
    default = {}
  }

  vhub_connection_enabled = try(var.sidecar_virtual_network.virtual_hub_connection.enabled, true)
  vhub_connection_name = coalesce(
    try(var.sidecar_virtual_network.virtual_hub_connection.name, null),
    "${local.sidecar_vnet_name}-to-vhub"
  )
  vhub_connection_internet_security_enabled = try(var.sidecar_virtual_network.virtual_hub_connection.internet_security_enabled, false)

  primary_outbound_endpoint_key = length(var.outbound_endpoints) > 0 ? sort(keys(var.outbound_endpoints))[0] : null

  forwarding_rulesets_avm = {
    for ruleset_key, ruleset in var.forwarding_rulesets : ruleset_key => {
      name                   = try(ruleset.name, null)
      tags                   = try(ruleset.tags, null)
      merge_with_module_tags = true

      link_with_outbound_endpoint_virtual_network         = true
      metadata_for_outbound_endpoint_virtual_network_link = null

      additional_virtual_network_links = {
        for link_key, link in try(ruleset.virtual_network_links, {}) : link_key => {
          name     = try(link.name, null)
          vnet_id  = link.vnet_id
          metadata = try(link.metadata, null)
        } if try(link.enabled, true)
      }

      rules = {
        for rule_key, rule in try(ruleset.rules, {}) : rule_key => {
          name        = try(rule.name, null)
          domain_name = rule.domain_name

          destination_ip_addresses = {
            for server in rule.target_dns_servers : server.ip_address => tostring(try(server.port, 53))
          }

          enabled  = try(rule.enabled, true)
          metadata = try(rule.metadata, null)
        }
      }
    }
  }

  inbound_endpoints_avm = {
    for key, ep in local.inbound_endpoints_effective : key => {
      name                         = try(ep.name, null)
      subnet_name                  = local.inbound_subnet_name
      private_ip_allocation_method = try(ep.private_ip_allocation_method, "Dynamic")
      private_ip_address           = try(ep.private_ip_address, null)
      tags                         = try(ep.tags, null)
      merge_with_module_tags       = true
    }
  }

  outbound_endpoints_avm = {
    for key, ep in var.outbound_endpoints : key => {
      name                   = try(ep.name, null)
      tags                   = try(ep.tags, null)
      merge_with_module_tags = true
      subnet_name            = local.outbound_subnet_name

      forwarding_ruleset = (
        length(var.forwarding_rulesets) > 0 && key == local.primary_outbound_endpoint_key
        ? local.forwarding_rulesets_avm
        : null
      )
    }
  }
}

module "sidecar_virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name      = local.sidecar_vnet_name
  location  = var.location
  parent_id = var.resource_group_id

  address_space = toset(var.sidecar_virtual_network.address_space)
  tags          = local.sidecar_vnet_tags

  subnets = {
    inbound = {
      name             = local.inbound_subnet_name
      address_prefixes = var.inbound_subnet.address_prefixes

      delegations = [
        {
          name = "dnsResolvers"
          service_delegation = {
            name = "Microsoft.Network/dnsResolvers"
          }
        }
      ]
    }
    outbound = {
      name             = local.outbound_subnet_name
      address_prefixes = var.outbound_subnet.address_prefixes

      delegations = [
        {
          name = "dnsResolvers"
          service_delegation = {
            name = "Microsoft.Network/dnsResolvers"
          }
        }
      ]
    }
  }
}

module "sidecar_virtual_hub_connection" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection"
  version = "0.13.5"

  virtual_network_connections = local.vhub_connection_enabled ? {
    sidecar = {
      name                      = local.vhub_connection_name
      virtual_hub_id            = var.virtual_hub_id
      remote_virtual_network_id = module.sidecar_virtual_network.resource_id
      internet_security_enabled = local.vhub_connection_internet_security_enabled
    }
  } : {}
}

module "dns_resolver" {
  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  virtual_network_resource_id = module.sidecar_virtual_network.resource_id

  tags = var.tags

  inbound_endpoints  = local.inbound_endpoints_avm
  outbound_endpoints = local.outbound_endpoints_avm
}
