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

variable "tags" {
  description = "Tags applied to the firewall policy."
  type        = map(string)
  default     = {}
}

variable "rule_collection_groups" {
  description = "Custom rule collection groups to create for this firewall policy."
  # NOTE: terraform.tfvars does not allow function calls (like tomap()).
  # To keep tfvars ergonomics and allow heterogeneous group shapes (e.g., baseline placeholder vs aks-egress),
  # this input is intentionally loose and is normalized inside main.tf.
  type    = any
  default = {}

  validation {
    condition     = can(keys(var.rule_collection_groups))
    error_message = "rule_collection_groups must be a map/object keyed by rule collection group name."
  }
}

variable "builtins" {
  description = "Optional built-in rule sets that expand into rule_collection_groups (e.g., AKS egress baseline)."
  type = object({
    aks_egress = optional(object({
      enabled = bool

      # Required when enabled=true
      source_addresses = list(string)

      # Optional additions (the module will add region-specific AKS FQDNs automatically)
      additional_fqdns = optional(list(string), [])

      # Required when enabled=true
      dns_servers = list(string)
      ntp_servers = list(string)

      # Optional: destinations you want as TCP/443 network rules rather than app rules.
      extra_tcp_fqdns = optional(list(string), [])
    }))
  })

  default = {
    aks_egress = null
  }
}
