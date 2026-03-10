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

variable "enable_telemetry" {
  description = "Controls whether AVM module telemetry is enabled. Mirrors the AVM module input `enable_telemetry`."
  type        = bool
  default     = true
}

variable "tags" {
  description = "(Optional) Module-level tags passed to the AVM module input `tags`."
  type        = map(string)
  default     = null
}

variable "default_naming_convention" {
  description = "(Optional) Pass-through for the AVM module input `default_naming_convention`."
  type        = any
  default     = {}
}

variable "default_naming_convention_sequence" {
  description = "(Optional) Pass-through for the AVM module input `default_naming_convention_sequence`."
  type = object({
    starting_number = number
    padding_format  = string
  })
  default = {
    starting_number = 1
    padding_format  = "%03d"
  }
}

variable "retry" {
  description = "(Optional) Pass-through for the AVM module input `retry`."
  type        = any
  default     = {}
}

variable "timeouts" {
  description = "(Optional) Pass-through for the AVM module input `timeouts`."
  type        = any
  default     = {}
}

variable "private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix" {
  description = "(Optional) Temporary AVM migration input for private DNS zone VNet links. Mirrors the AVM module variable of the same name."
  type        = string
  default     = ""
}

variable "virtual_wan_settings" {
  description = "Virtual WAN settings in the native AVM module schema. This is passed through to the AVM module input `virtual_wan_settings`."
  type        = any
  default     = {}
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
  description = "Virtual hubs in the native AVM module schema. This is passed through to the AVM module input `virtual_hubs`."
  type        = any
  default     = {}
}

