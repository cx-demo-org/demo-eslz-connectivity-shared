locals {
  virtual_wan_sku = try(var.virtual_wan.sku, "Standard")
  virtual_wan_tags = merge(
    try(local.rg[var.virtual_wan.resource_group_key].tags, {}),
    try(var.virtual_wan.tags, {})
  )
}

locals {
  virtual_hubs_effective = {
    for hub_key, hub in var.virtual_hubs : hub_key => {
      location            = hub.location
      resource_group_id   = local.rg[hub.resource_group_key].id
      resource_group_name = local.rg[hub.resource_group_key].name
      tags = merge(
        local.rg[hub.resource_group_key].tags,
        try(hub.tags, {})
      )

      name           = hub.name
      address_prefix = hub.address_prefix

      firewall             = try(hub.firewall, null)
      expressroute_gateway = try(hub.expressroute_gateway, null)
      site_to_site_vpn     = try(hub.site_to_site_vpn, null)
      private_dns_resolver = try(hub.private_dns_resolver, null)
      private_dns_zones    = try(hub.private_dns_zones, null)
    }
  }
}

locals {
  s2s_vpn_gateway_key_by_hub = {
    for hub_key, hub in var.virtual_hubs : hub_key => (
      try(hub.site_to_site_vpn, null) == null
      ? null
      : (length(try(hub.site_to_site_vpn.vpn_gateways, {})) == 1
        ? one(keys(hub.site_to_site_vpn.vpn_gateways))
        : null
      )
    )
  }

  s2s_vpn_site_link_numbers_by_hub = {
    for hub_key, hub in var.virtual_hubs : hub_key => {
      for site_key, site in try(hub.site_to_site_vpn.vpn_sites, {}) : site_key => {
        for idx, link in site.links : link.name => idx + 1
      }
    }
  }
}

module "resource_groups" {
  for_each = var.resource_groups

  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags

  enable_telemetry = false
}

data "azurerm_resource_group" "rg" {
  for_each = var.existing_resource_groups

  name = each.value.name
}

locals {
  rg = merge(
    { for rg_key, rg_mod in module.resource_groups : rg_key => { id = rg_mod.resource_id, name = rg_mod.name, location = rg_mod.location, tags = coalesce(try(rg_mod.resource.tags, null), try(var.resource_groups[rg_key].tags, {})) } },
    { for rg_key, rg_data in data.azurerm_resource_group.rg : rg_key => { id = rg_data.id, name = rg_data.name, location = rg_data.location, tags = rg_data.tags } }
  )
}

module "expressroute_circuits" {
  for_each = var.expressroute_circuits

  source = "./modules/expressroute_circuit"

  name                = each.value.name
  location            = coalesce(try(each.value.location, null), local.rg[each.value.resource_group_key].location)
  resource_group_name = local.rg[each.value.resource_group_key].name

  sku = each.value.sku

  tags             = merge(local.rg[each.value.resource_group_key].tags, try(each.value.tags, {}))
  exr_circuit_tags = try(each.value.exr_circuit_tags, null)

  service_provider_name          = try(each.value.service_provider_name, null)
  peering_location               = try(each.value.peering_location, null)
  bandwidth_in_mbps              = try(each.value.bandwidth_in_mbps, null)
  express_route_port_resource_id = try(each.value.express_route_port_resource_id, null)
  bandwidth_in_gbps              = try(each.value.bandwidth_in_gbps, null)

  allow_classic_operations = try(each.value.allow_classic_operations, false)
  authorization_key        = try(each.value.authorization_key, null)

  peerings                             = try(each.value.peerings, {})
  express_route_circuit_authorizations = try(each.value.express_route_circuit_authorizations, {})
  er_gw_connections                    = try(each.value.er_gw_connections, {})
  vnet_gw_connections                  = try(each.value.vnet_gw_connections, {})
  circuit_connections                  = try(each.value.circuit_connections, {})

  diagnostic_settings = try(each.value.diagnostic_settings, {})
  role_assignments    = try(each.value.role_assignments, {})
  lock                = try(each.value.lock, null)

  enable_telemetry = try(each.value.enable_telemetry, true)
}

module "firewall_policies" {
  for_each = var.firewall_policies

  source = "./modules/fwpolicy"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = local.rg[each.value.resource_group_key].name

  tags = merge(local.rg[each.value.resource_group_key].tags, try(each.value.tags, {}))

  builtins               = try(each.value.builtins, null)
  rule_collection_groups = try(each.value.rule_collection_groups, {})
}

data "azurerm_firewall_policy" "existing" {
  for_each = var.existing_firewall_policies

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

module "alz_connectivity" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  providers = {
    azurerm = azurerm.wan
    azapi   = azapi.wan
  }

  enable_telemetry = try(var.virtual_wan.enable_module_telemetry, true)
  tags             = local.virtual_wan_tags

  virtual_wan_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }

    virtual_wan = {
      name                = var.virtual_wan.name
      location            = var.virtual_wan.location
      resource_group_name = local.rg[var.virtual_wan.resource_group_key].name
      type                = local.virtual_wan_sku

      allow_branch_to_branch_traffic = try(var.virtual_wan.allow_branch_to_branch_traffic, true)
      disable_vpn_encryption         = try(var.virtual_wan.disable_vpn_encryption, false)

      tags = local.virtual_wan_tags
    }
  }

  virtual_hubs = {
    for hub_key, hub in local.virtual_hubs_effective : hub_key => {
      location = hub.location

      enabled_resources = {
        firewall                              = hub.firewall != null
        firewall_policy                       = false
        bastion                               = false
        virtual_network_gateway_express_route = hub.expressroute_gateway != null
        virtual_network_gateway_vpn           = hub.site_to_site_vpn != null && local.s2s_vpn_gateway_key_by_hub[hub_key] != null
        private_dns_zones                     = hub.private_dns_zones != null
        private_dns_resolver                  = hub.private_dns_resolver != null
        sidecar_virtual_network               = hub.private_dns_resolver != null
      }

      hub = {
        name           = hub.name
        address_prefix = hub.address_prefix
        parent_id      = hub.resource_group_id
        tags           = hub.tags
      }

      virtual_network_gateways = {
        express_route = hub.expressroute_gateway != null ? {
          name                          = try(hub.expressroute_gateway.name, null)
          allow_non_virtual_wan_traffic = try(hub.expressroute_gateway.allow_non_virtual_wan_traffic, false)
          scale_units                   = try(hub.expressroute_gateway.scale_units, 1)
          tags                          = merge(hub.tags, try(hub.expressroute_gateway.tags, {}))
        } : {}

        vpn = hub.site_to_site_vpn != null && local.s2s_vpn_gateway_key_by_hub[hub_key] != null ? {
          name = try(
            hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].name,
            null
          )
          bgp_route_translation_for_nat_enabled = try(
            hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].bgp_route_translation_for_nat_enabled,
            null
          )
          bgp_settings       = try(hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].bgp_settings, null)
          routing_preference = try(hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].routing_preference, null)
          scale_unit         = try(hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].scale_unit, null)
          tags               = merge(hub.tags, try(hub.site_to_site_vpn.vpn_gateways[local.s2s_vpn_gateway_key_by_hub[hub_key]].tags, {}))
        } : {}
      }

      vpn_sites = hub.site_to_site_vpn != null ? {
        for site_key, site in try(hub.site_to_site_vpn.vpn_sites, {}) : site_key => {
          name          = site.name
          links         = site.links
          address_cidrs = try(site.address_cidrs, null)
          device_model  = try(site.device_model, null)
          device_vendor = try(site.device_vendor, null)
          o365_policy   = try(site.o365_policy, null)
          tags          = merge(hub.tags, try(site.tags, {}))
        }
      } : {}

      vpn_site_connections = hub.site_to_site_vpn != null && local.s2s_vpn_gateway_key_by_hub[hub_key] != null ? {
        for connection_key, connection in try(hub.site_to_site_vpn.vpn_site_connections, {}) : connection_key => {
          name                = connection.name
          remote_vpn_site_key = connection.vpn_site_key

          vpn_links = [
            for link in connection.vpn_links : {
              name                 = link.name
              egress_nat_rule_ids  = try(link.egress_nat_rule_ids, null)
              ingress_nat_rule_ids = try(link.ingress_nat_rule_ids, null)
              vpn_site_link_number = local.s2s_vpn_site_link_numbers_by_hub[hub_key][connection.vpn_site_key][link.vpn_site_link_name]
              vpn_site_key         = connection.vpn_site_key
              bandwidth_mbps       = try(link.bandwidth_mbps, null)
              bgp_enabled          = try(link.bgp_enabled, null)
              connection_mode      = try(link.connection_mode, null)
              ipsec_policy         = try(link.ipsec_policy, null)
              protocol             = try(link.protocol, null)
              ratelimit_enabled    = try(link.ratelimit_enabled, null)
              route_weight         = try(link.route_weight, null)
              shared_key           = try(link.shared_key, null)

              local_azure_ip_address_enabled        = try(link.local_azure_ip_address_enabled, null)
              policy_based_traffic_selector_enabled = try(link.policy_based_traffic_selector_enabled, null)

              # Not supported by this repo's schema (expects ip_configuration_id).
              custom_bgp_addresses = null
            }
          ]

          internet_security_enabled = try(connection.internet_security_enabled, null)
          routing                   = try(connection.routing, null)
          traffic_selector_policy   = try(connection.traffic_selector_policy, null)
        } if connection.vpn_gateway_key == local.s2s_vpn_gateway_key_by_hub[hub_key]
      } : {}

      private_dns_zones = hub.private_dns_zones != null ? hub.private_dns_zones : {}

      sidecar_virtual_network = hub.private_dns_resolver != null ? {
        name          = coalesce(try(hub.private_dns_resolver.sidecar_virtual_network.name, null), "${coalesce(try(hub.private_dns_resolver.name, null), "${hub.name}-pdr")}-sidecar")
        parent_id     = local.rg[coalesce(try(var.virtual_hubs[hub_key].private_dns_resolver.resource_group_key, null), var.virtual_hubs[hub_key].resource_group_key)].id
        address_space = try(hub.private_dns_resolver.sidecar_virtual_network.address_space, null)
        tags = merge(
          local.rg[coalesce(try(var.virtual_hubs[hub_key].private_dns_resolver.resource_group_key, null), var.virtual_hubs[hub_key].resource_group_key)].tags,
          hub.tags,
          try(hub.private_dns_resolver.tags, {}),
          try(hub.private_dns_resolver.sidecar_virtual_network.tags, {})
        )

        virtual_network_connection_settings = try(hub.private_dns_resolver.sidecar_virtual_network.virtual_hub_connection.enabled, true) ? {
          name = coalesce(
            try(hub.private_dns_resolver.sidecar_virtual_network.virtual_hub_connection.name, null),
            "${coalesce(try(hub.private_dns_resolver.sidecar_virtual_network.name, null), "${coalesce(try(hub.private_dns_resolver.name, null), "${hub.name}-pdr")}-sidecar")}-to-vhub"
          )
          internet_security_enabled = try(hub.private_dns_resolver.sidecar_virtual_network.virtual_hub_connection.internet_security_enabled, false)
        } : null

        subnets = {
          inbound = {
            name             = hub.private_dns_resolver.inbound_subnet.name
            address_prefixes = hub.private_dns_resolver.inbound_subnet.address_prefixes

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
            name             = hub.private_dns_resolver.outbound_subnet.name
            address_prefixes = hub.private_dns_resolver.outbound_subnet.address_prefixes

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
      } : null

      private_dns_resolver = hub.private_dns_resolver != null ? {
        name                = coalesce(try(hub.private_dns_resolver.name, null), "${hub.name}-pdr")
        resource_group_name = local.rg[coalesce(try(var.virtual_hubs[hub_key].private_dns_resolver.resource_group_key, null), var.virtual_hubs[hub_key].resource_group_key)].name

        default_inbound_endpoint_enabled = false

        inbound_endpoints = {
          for key, ep in(
            length(try(hub.private_dns_resolver.inbound_endpoints, {})) > 0
            ? try(hub.private_dns_resolver.inbound_endpoints, {})
            : { default = {} }
            ) : key => {
            name                         = try(ep.name, null)
            subnet_name                  = hub.private_dns_resolver.inbound_subnet.name
            private_ip_allocation_method = try(ep.private_ip_allocation_method, "Dynamic")
            private_ip_address           = try(ep.private_ip_address, null)
            tags                         = try(ep.tags, null)
            merge_with_module_tags       = true
          }
        }

        outbound_endpoints = {
          for key, ep in try(hub.private_dns_resolver.outbound_endpoints, {}) : key => {
            name                   = try(ep.name, null)
            tags                   = try(ep.tags, null)
            merge_with_module_tags = true
            subnet_name            = hub.private_dns_resolver.outbound_subnet.name

            forwarding_ruleset = (
              length(try(hub.private_dns_resolver.forwarding_rulesets, {})) > 0 && key == (
                length(try(hub.private_dns_resolver.outbound_endpoints, {})) > 0
                ? sort(keys(try(hub.private_dns_resolver.outbound_endpoints, {})))[0]
                : null
              )
              ? {
                for ruleset_key, ruleset in try(hub.private_dns_resolver.forwarding_rulesets, {}) : ruleset_key => {
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
              : null
            )
          }
        }

        tags = merge(
          local.rg[coalesce(try(var.virtual_hubs[hub_key].private_dns_resolver.resource_group_key, null), var.virtual_hubs[hub_key].resource_group_key)].tags,
          hub.tags,
          try(hub.private_dns_resolver.tags, {})
        )
      } : null

      firewall = hub.firewall != null ? {
        name     = try(hub.firewall.name, null)
        sku_name = "AZFW_Hub"
        sku_tier = coalesce(try(hub.firewall.sku_tier, null), "Standard")
        firewall_policy_id = coalesce(
          try(hub.firewall.firewall_policy_id, null),
          try(local.firewall_policy_ids[hub.firewall.firewall_policy_key], null)
        )
        zones = []
        tags  = coalesce(try(hub.firewall.tags, null), hub.tags)
        } : {
        name               = null
        sku_name           = "AZFW_Hub"
        sku_tier           = "Standard"
        firewall_policy_id = null
        zones              = []
        tags               = null
      }
    }
  }
}

locals {
  virtual_hub_ids          = module.alz_connectivity.virtual_hub_resource_ids
  virtual_hub_firewall_ids = module.alz_connectivity.firewall_resource_ids
}

check "s2s_vpn_single_gateway_in_owning_mode" {
  assert {
    condition = alltrue([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.site_to_site_vpn, null) == null
        || length(try(hub.site_to_site_vpn.vpn_gateways, {})) <= 1
      )
    ])
    error_message = "In owning mode (virtual_wan configured), AVM supports only one site_to_site_vpn.vpn_gateways entry per hub."
  }
}

check "s2s_vpn_connections_reference_valid_site_link" {
  assert {
    condition = alltrue(flatten([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.site_to_site_vpn, null) == null
        ? [true]
        : [
          for connection_key, connection in try(hub.site_to_site_vpn.vpn_site_connections, {}) : alltrue([
            for link in connection.vpn_links : try(
              local.s2s_vpn_site_link_numbers_by_hub[hub_key][connection.vpn_site_key][link.vpn_site_link_name],
              null
            ) != null
          ])
        ]
      )
    ]))
    error_message = "Each site_to_site_vpn.vpn_site_connections[*].vpn_links[*].vpn_site_link_name must match a link name in the referenced vpn_site."
  }
}

check "s2s_vpn_custom_bgp_addresses_not_supported_in_owning_mode" {
  assert {
    condition = alltrue(flatten([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.site_to_site_vpn, null) == null
        ? [true]
        : flatten([
          for connection_key, connection in try(hub.site_to_site_vpn.vpn_site_connections, {}) : [
            for link in connection.vpn_links : length(try(link.custom_bgp_addresses, [])) == 0
          ]
        ])
      )
    ]))
    error_message = "In owning mode, site_to_site_vpn.vpn_site_connections[*].vpn_links[*].custom_bgp_addresses is not supported (this repo uses ip_configuration_id; AVM expects an instance number)."
  }
}

check "s2s_vpn_connections_match_selected_gateway" {
  assert {
    condition = alltrue(flatten([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.site_to_site_vpn, null) == null
        ? [true]
        : [
          for connection_key, connection in try(hub.site_to_site_vpn.vpn_site_connections, {}) : (
            local.s2s_vpn_gateway_key_by_hub[hub_key] != null
            && connection.vpn_gateway_key == local.s2s_vpn_gateway_key_by_hub[hub_key]
          )
        ]
      )
    ]))
    error_message = "In owning mode, configuring vpn_site_connections requires exactly one vpn_gateway, and all connections must reference that vpn_gateway_key."
  }
}

check "firewall_policy_required" {
  assert {
    condition = alltrue([
      for hub_key, hub in local.virtual_hubs_effective : (
        hub.firewall == null || coalesce(
          try(hub.firewall.firewall_policy_id, null),
          try(local.firewall_policy_ids[hub.firewall.firewall_policy_key], null)
        ) != null
      )
    ])
    error_message = "When a hub has firewall enabled, firewall_policy_id (or firewall_policy_key) must be provided."
  }
}

locals {
  firewall_policy_ids = merge(
    { for policy_key, policy_mod in module.firewall_policies : policy_key => policy_mod.id },
    { for policy_key, policy_data in data.azurerm_firewall_policy.existing : policy_key => policy_data.id }
  )
}

