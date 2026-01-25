variable "location" {
  description = "Azure region for the Virtual WAN and hub resources."
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Name of the existing resource group that hosts the Virtual WAN resources."
  type        = string
  default     = "msft-prod-connectivity-rg"
}

variable "virtual_wan_name" {
  description = "Name for the Virtual WAN resource."
  type        = string
  default     = "msft-prod-sea-vwan"
}

variable "virtual_wan_sku" {
  description = "Virtual WAN SKU. Allowed values are Standard or Basic."
  type        = string
  default     = "Standard"
}

variable "allow_branch_to_branch_traffic" {
  description = "Toggle branch-to-branch traffic within the Virtual WAN."
  type        = bool
  default     = true
}

variable "disable_vpn_encryption" {
  description = "Disable VPN encryption on the Virtual WAN (not recommended)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Optional tags applied to all resources managed by this module."
  type        = map(string)
  default = {
    environment = "prod"
    workload    = "msft-vwan"
  }
}

variable "enable_module_telemetry" {
  description = "Enable AVM module telemetry (recommended)."
  type        = bool
  default     = true
}
