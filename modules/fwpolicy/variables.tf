variable "name" {
  description = "Azure Firewall Policy name."
  type        = string
}

variable "location" {
  description = "Azure region for the Firewall Policy."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name that will contain the Firewall Policy."
  type        = string
}

variable "firewall_policy_sku" {
  description = "Firewall Policy SKU. Typically 'Standard' or 'Premium'."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_policy_sku)
    error_message = "firewall_policy_sku must be one of: Standard, Premium."
  }
}

variable "tags" {
  description = "Tags applied to the firewall policy."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Controls whether AVM module telemetry is enabled for the firewall policy module."
  type        = bool
  default     = false
}

variable "rule_collection_groups" {
  description = "Rule collection groups to create for this firewall policy, already in the AVM rule_collection_groups module schema."
  type = map(object({
    priority = number

    # These should match the AVM module inputs:
    # - firewall_policy_rule_collection_group_application_rule_collection
    # - firewall_policy_rule_collection_group_network_rule_collection
    # - firewall_policy_rule_collection_group_nat_rule_collection
    application_rule_collection = optional(list(any), null)
    network_rule_collection     = optional(list(any), null)
    nat_rule_collection         = optional(list(any), null)
  }))

  default = {}
}
