variable "location" {
  description = "Azure region for the VPN resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the VPN resources will be created."
  type        = string
}

variable "virtual_hub_id" {
  description = "Virtual Hub resource ID for the S2S VPN Gateway."
  type        = string
}

variable "virtual_wan_id" {
  description = "Virtual WAN resource ID for VPN Sites."
  type        = string
}

variable "tags" {
  description = "Base tags applied to VPN resources."
  type        = map(string)
  default     = {}
}

variable "vpn_gateways" {
  description = "Map of S2S VPN Gateways to create in the hub."

  type = map(object({
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
  }))

  default = {}
}

variable "vpn_sites" {
  description = "Map of VPN Sites to create and link to the Virtual WAN."

  type = map(object({
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
  }))

  default = {}
}

variable "vpn_site_connections" {
  description = "Map of VPN site connections to create between gateways and sites."

  type = map(object({
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
  }))

  default = {}

  validation {
    condition = alltrue([
      for conn_key, conn in var.vpn_site_connections : contains(keys(var.vpn_gateways), conn.vpn_gateway_key)
    ])
    error_message = "vpn_site_connections[*].vpn_gateway_key must reference an entry in vpn_gateways."
  }

  validation {
    condition = alltrue([
      for conn_key, conn in var.vpn_site_connections : contains(keys(var.vpn_sites), conn.vpn_site_key)
    ])
    error_message = "vpn_site_connections[*].vpn_site_key must reference an entry in vpn_sites."
  }

  validation {
    condition = alltrue([
      for conn_key, conn in var.vpn_site_connections : alltrue([
        for link in conn.vpn_links : contains([
          for site_link in var.vpn_sites[conn.vpn_site_key].links : site_link.name
        ], link.vpn_site_link_name)
      ])
    ])
    error_message = "vpn_site_connections[*].vpn_links[*].vpn_site_link_name must exist in the referenced vpn_sites[*].links list."
  }
}
