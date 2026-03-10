variable "resource_groups" {
  description = "Resource groups managed by Terraform keyed by a short logical name. Components reference these keys."

  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))

  default = {}
}

variable "hub_subscription_id" {
  description = "Subscription ID used for hub resources in this environment (vHub, Azure Firewall, Firewall Policy, and RG lookups). Leave null to rely on the authenticated default subscription (not recommended when you have multiple subscriptions)."
  type        = string
  default     = null
}

variable "hub_tenant_id" {
  description = "Tenant ID used for hub resources in this environment. Leave null to rely on the authenticated default tenant."
  type        = string
  default     = null
}

variable "virtual_wan_subscription_id" {
  description = "Optional subscription ID to use for Virtual WAN create/lookup. Set this when the vWAN lives in a different subscription than the hub resources. Defaults to hub_subscription_id when unset."
  type        = string
  default     = null
}

variable "virtual_wan_tenant_id" {
  description = "Optional tenant ID to use for Virtual WAN create/lookup. Defaults to hub_tenant_id when unset."
  type        = string
  default     = null
}

variable "existing_resource_groups" {
  description = "Existing resource groups (data lookup only) keyed by a short logical name. Useful during migration when you don't want Terraform to manage the RG itself."

  type = map(object({
    name = string
  }))

  default = {}
}

variable "virtual_wan" {
  description = "Virtual WAN managed by Terraform (created in this environment's state)."

  type = object({
    name               = string
    resource_group_key = string
    location           = string

    sku = optional(string)

    allow_branch_to_branch_traffic = optional(bool)
    disable_vpn_encryption         = optional(bool)

    enable_module_telemetry = optional(bool)
    tags                    = optional(map(string))
  })

  # Required (prod/owning mode only).
}

variable "firewall_policies" {
  description = "Firewall policies managed by Terraform keyed by logical name."

  type = map(object({
    name               = string
    resource_group_key = string
    location           = string

    tags = optional(map(string))

    # Optional: built-in rule sets that expand into rule_collection_groups (opt-in).
    builtins = optional(any)

    # Optional: fully custom rules to build per-policy.
    # Shape is validated inside the fwpolicy module.
    rule_collection_groups = optional(any)
  }))

  default = {}
}

variable "existing_firewall_policies" {
  description = "Existing firewall policies (data lookup) keyed by logical name."

  type = map(object({
    name                = string
    resource_group_name = string
  }))

  default = {}
}

variable "expressroute_circuits" {
  description = "ExpressRoute Circuits to create (optional). Each circuit is created in a specified resource group via resource_group_key."

  type = map(object({
    name               = string
    resource_group_key = string

    location = optional(string)

    sku = object({
      tier   = string
      family = string
    })

    # Provider-based circuits.
    service_provider_name = optional(string)
    peering_location      = optional(string)
    bandwidth_in_mbps     = optional(number)

    # ExpressRoute Direct circuits.
    express_route_port_resource_id = optional(string)
    bandwidth_in_gbps              = optional(number)

    allow_classic_operations = optional(bool, false)
    authorization_key        = optional(string)

    tags             = optional(map(string))
    exr_circuit_tags = optional(map(string))

    # Advanced (optional) - passed through to AVM module.
    peerings                             = optional(any, {})
    express_route_circuit_authorizations = optional(any, {})
    er_gw_connections                    = optional(any, {})
    vnet_gw_connections                  = optional(any, {})
    circuit_connections                  = optional(any, {})
    diagnostic_settings                  = optional(any, {})
    role_assignments                     = optional(any, {})
    lock                                 = optional(any)
    enable_telemetry                     = optional(bool, true)
  }))

  default = {}

  validation {
    condition     = alltrue([for k, c in var.expressroute_circuits : contains(keys(merge(var.resource_groups, var.existing_resource_groups)), c.resource_group_key)])
    error_message = "Each expressroute_circuits[*].resource_group_key must exist in resource_groups or existing_resource_groups."
  }
}

variable "virtual_hubs" {
  description = "Virtual hubs keyed by logical name. Each hub is created and can optionally have an Azure Firewall attached."

  type = map(object({
    name               = string
    resource_group_key = string
    location           = string
    address_prefix     = string

    tags = optional(map(string))

    # Optional: Private DNS Zones configuration (passed through to the AVM alz_connectivity module).
    # Shape matches the AVM module's virtual_hubs[*].private_dns_zones input.
    private_dns_zones = optional(any)

    private_dns_resolver = optional(object({
      # Optional separate RG placement for DNS resources.
      # If unset, defaults to the hub's resource_group_key.
      resource_group_key = optional(string)

      # Private DNS Resolver name. If unset, defaults to "<hub-name>-pdr".
      name = optional(string)

      # Sidecar VNet used to host resolver endpoints.
      sidecar_virtual_network = object({
        name          = optional(string)
        address_space = list(string)
        tags          = optional(map(string))

        virtual_hub_connection = optional(any)
      })

      # Subnets for the resolver endpoints.
      inbound_subnet = object({
        name             = optional(string)
        address_prefixes = list(string)
        network_security_group = optional(object({
          id = string
        }))
      })

      outbound_subnet = object({
        name             = optional(string)
        address_prefixes = list(string)
        network_security_group = optional(object({
          id = string
        }))
      })

      # Optional endpoints + forwarding rules.
      inbound_endpoints   = optional(any, {})
      outbound_endpoints  = optional(any, {})
      forwarding_rulesets = optional(any, {})

      tags = optional(map(string))
    }))

    firewall = optional(object({
      name     = string
      sku_tier = optional(string)

      firewall_policy_key = optional(string)
      firewall_policy_id  = optional(string)

      tags = optional(map(string))
    }))

    expressroute_gateway = optional(object({
      name = optional(string)

      allow_non_virtual_wan_traffic = optional(bool, false)
      scale_units                   = optional(number, 1)

      tags = optional(map(string))
    }))

    site_to_site_vpn = optional(object({
      vpn_gateways = optional(map(object({
        name                                  = string
        tags                                  = optional(map(string))
        bgp_route_translation_for_nat_enabled = optional(bool)
        bgp_settings = optional(object({
          instance_0_bgp_peering_address = optional(object({
            custom_ips = list(string)
          }))
          instance_1_bgp_peering_address = optional(object({
            custom_ips = list(string)
          }))
          peer_weight = number
          asn         = number
        }))
        routing_preference = optional(string)
        scale_unit         = optional(number)
      })), {})

      vpn_sites = optional(map(object({
        name          = string
        address_cidrs = optional(list(string))
        device_model  = optional(string)
        device_vendor = optional(string)
        tags          = optional(map(string))
        links = list(object({
          name = string
          bgp = optional(object({
            asn             = number
            peering_address = string
          }))
          fqdn          = optional(string)
          ip_address    = optional(string)
          provider_name = optional(string)
          speed_in_mbps = optional(number)
        }))
        o365_policy = optional(object({
          traffic_category = object({
            allow_endpoint_enabled    = optional(bool)
            default_endpoint_enabled  = optional(bool)
            optimize_endpoint_enabled = optional(bool)
          })
        }))
      })), {})

      vpn_site_connections = optional(map(object({
        name            = string
        vpn_gateway_key = string
        vpn_site_key    = string
        vpn_links = list(object({
          name                 = string
          vpn_site_link_name   = string
          egress_nat_rule_ids  = optional(list(string))
          ingress_nat_rule_ids = optional(list(string))
          bandwidth_mbps       = optional(number)
          bgp_enabled          = optional(bool)
          connection_mode      = optional(string)
          ipsec_policy = optional(object({
            dh_group                 = string
            ike_encryption_algorithm = string
            ike_integrity_algorithm  = string
            encryption_algorithm     = string
            integrity_algorithm      = string
            pfs_group                = string
            sa_data_size_kb          = string
            sa_lifetime_sec          = string
          }))
          protocol                              = optional(string)
          ratelimit_enabled                     = optional(bool)
          route_weight                          = optional(number)
          shared_key                            = optional(string)
          local_azure_ip_address_enabled        = optional(bool)
          policy_based_traffic_selector_enabled = optional(bool)
          custom_bgp_addresses = optional(list(object({
            ip_address          = string
            ip_configuration_id = string
          })))
        }))
        internet_security_enabled = optional(bool)
        routing = optional(object({
          associated_route_table = string
          propagated_route_table = optional(object({
            route_table_ids = optional(list(string))
            labels          = optional(list(string))
          }))
          inbound_route_map_id  = optional(string)
          outbound_route_map_id = optional(string)
        }))
        traffic_selector_policy = optional(object({
          local_address_ranges  = list(string)
          remote_address_ranges = list(string)
        }))
      })), {})
    }))
  }))

  validation {
    condition     = alltrue([for hub_key, hub in var.virtual_hubs : contains(keys(merge(var.resource_groups, var.existing_resource_groups)), hub.resource_group_key)])
    error_message = "Each virtual_hubs[*].resource_group_key must exist in resource_groups or existing_resource_groups."
  }

  validation {
    condition = alltrue([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.expressroute_gateway, null) == null || try(hub.expressroute_gateway.scale_units, 1) >= 1
      )
    ])
    error_message = "For any virtual_hubs[*] with expressroute_gateway configured, scale_units must be >= 1."
  }

  validation {
    condition = alltrue([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.firewall, null) == null || (
          try(hub.firewall.firewall_policy_id, null) != null || try(hub.firewall.firewall_policy_key, null) != null
        )
      )
    ])
    error_message = "For any virtual_hubs[*] with firewall configured, you must set firewall.firewall_policy_id or firewall.firewall_policy_key."
  }

  validation {
    condition = alltrue([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.site_to_site_vpn, null) == null
        || length(try(hub.site_to_site_vpn.vpn_site_connections, {})) == 0
        || (
          length(try(hub.site_to_site_vpn.vpn_gateways, {})) > 0
          && length(try(hub.site_to_site_vpn.vpn_sites, {})) > 0
        )
      )
    ])
    error_message = "When site_to_site_vpn.vpn_site_connections are configured, you must also define vpn_gateways and vpn_sites."
  }

  validation {
    condition = alltrue([
      for hub_key, hub in var.virtual_hubs : (
        try(hub.private_dns_resolver.resource_group_key, null) == null
        ? true
        : contains(
          keys(merge(var.resource_groups, var.existing_resource_groups)),
          hub.private_dns_resolver.resource_group_key
        )
      )
    ])
    error_message = "For any virtual_hubs[*] with private_dns_resolver.resource_group_key set, that key must exist in resource_groups or existing_resource_groups."
  }
}

