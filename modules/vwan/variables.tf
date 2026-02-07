variable "name" {
  description = "Virtual WAN name."
  type        = string
}

variable "location" {
  description = "Azure region for the Virtual WAN."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the Virtual WAN will be created."
  type        = string
}

variable "sku" {
  description = "Virtual WAN type/SKU (e.g., Standard)."
  type        = string
  default     = "Standard"
}

variable "allow_branch_to_branch_traffic" {
  description = "Enable branch-to-branch traffic."
  type        = bool
  default     = true
}

variable "disable_vpn_encryption" {
  description = "Disable VPN encryption."
  type        = bool
  default     = false
}

variable "enable_module_telemetry" {
  description = "Enable AVM module telemetry."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the Virtual WAN resources."
  type        = map(string)
  default     = {}
}
