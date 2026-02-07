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
  description = "Optional subscription ID to use for Virtual WAN create/lookup. Set this when the vWAN lives in a different subscription than the hub resources (e.g., dev references a prod-owned vWAN). Defaults to hub_subscription_id when unset."
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
  description = "Virtual WAN managed by Terraform (created in this state). Set to null if you want to reference an existing VWAN via existing_virtual_wan."

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

  default = null

  validation {
    condition     = (var.virtual_wan == null) != (var.existing_virtual_wan == null)
    error_message = "You must set exactly one of virtual_wan (managed) or existing_virtual_wan (lookup)."
  }
}

variable "existing_virtual_wan" {
  description = "Existing Virtual WAN reference (data lookup). Use this for non-owning environments (e.g., dev referencing a prod-owned vWAN)."

  type = object({
    name                = string
    resource_group_name = string
  })

  default = null
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
}

