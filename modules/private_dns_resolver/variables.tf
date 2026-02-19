variable "name" {
  description = "Private DNS Resolver name."
  type        = string
}

variable "location" {
  description = "Azure region for the resolver and sidecar VNet."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the resolver and sidecar VNet will be created."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group id where the sidecar VNet will be created (used as parent_id for AVM VNet module)."
  type        = string
}

variable "virtual_hub_id" {
  description = "Virtual Hub resource ID. Used to optionally connect the sidecar VNet to the vHub."
  type        = string
}

variable "tags" {
  description = "Tags applied to resources created by this module."
  type        = map(string)
  default     = {}
}

variable "sidecar_virtual_network" {
  description = "Sidecar VNet configuration used to host the Private DNS Resolver endpoints."

  type = object({
    name          = optional(string)
    address_space = list(string)
    tags          = optional(map(string), {})

    virtual_hub_connection = optional(object({
      enabled                   = optional(bool, true)
      name                      = optional(string)
      internet_security_enabled = optional(bool, false)
    }), {})
  })
}

variable "inbound_subnet" {
  description = "Subnet for inbound endpoints (must be within the sidecar VNet address space)."

  type = object({
    name             = optional(string, "dns-inbound")
    address_prefixes = list(string)
  })
}

variable "outbound_subnet" {
  description = "Subnet for outbound endpoints (must be within the sidecar VNet address space)."

  type = object({
    name             = optional(string, "dns-outbound")
    address_prefixes = list(string)
  })
}

variable "inbound_endpoints" {
  description = "Map of inbound endpoints to create. If empty, a single default endpoint will be created."

  type = map(object({
    name                         = optional(string)
    private_ip_allocation_method = optional(string, "Dynamic")
    private_ip_address           = optional(string)
    tags                         = optional(map(string), {})
  }))

  default = {}
}

variable "outbound_endpoints" {
  description = "Map of outbound endpoints to create. Required when forwarding_rulesets is set."

  type = map(object({
    name = optional(string)
    tags = optional(map(string), {})
  }))

  default = {}
}

variable "forwarding_rulesets" {
  description = "Optional DNS forwarding rulesets (requires at least one outbound endpoint)."

  type = map(object({
    name = optional(string)
    tags = optional(map(string), {})

    # Optional additional VNet links. The sidecar VNet link is always created.
    virtual_network_links = optional(map(object({
      vnet_id  = string
      name     = optional(string)
      metadata = optional(map(string), {})
      enabled  = optional(bool, true)
    })), {})

    rules = optional(map(object({
      domain_name = string
      enabled     = optional(bool, true)
      metadata    = optional(map(string), {})
      target_dns_servers = list(object({
        ip_address = string
        port       = optional(number, 53)
      }))
    })), {})
  }))

  default = {}

  validation {
    condition     = length(var.forwarding_rulesets) == 0 || length(var.outbound_endpoints) == 1
    error_message = "When forwarding_rulesets is configured, you must configure exactly one outbound_endpoints entry (the AVM dnsresolver module models forwarding rulesets under a single outbound endpoint)."
  }
}
