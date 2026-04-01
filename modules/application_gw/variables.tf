variable "application_gateways" {
  description = <<-EOT
  Map of Application Gateways to create.

  This wrapper intentionally exposes the full AVM Application Gateway module surface by passing
  through all AVM inputs from each map value.

  In addition to the AVM inputs, each entry must also include:
  - resource_group_key
  - virtual_network_key
  - subnet_key
  And may include:
  - waf_policy_key (to attach a WAF policy created by this module)
  EOT
  type        = any
  default     = {}
}

variable "web_application_firewall_policies" {
  description = <<-EOT
  (Optional) Web Application Firewall (WAF) policies to create and then attach to App Gateways.

  Each policy object should include:
  - name
  - resource_group_key
  - location (optional)
  - tags (optional)

  Any additional properties (e.g., policy_settings, managed_rules, custom_rules) are optional.
  EOT
  type        = any
  default     = {}
}

variable "resource_groups" {
  description = "Resource groups map; must include name per key (dmz_vnet output shape is supported)."
  type        = any
}

variable "virtual_networks" {
  description = "Virtual networks map; must include subnets[*].resource_id per vnet/subnet key (dmz_vnet output shape is supported)."
  type        = any
}

variable "enable_telemetry" {
  description = "Pass-through flag for AVM modules that support telemetry."
  type        = bool
  default     = true
}
