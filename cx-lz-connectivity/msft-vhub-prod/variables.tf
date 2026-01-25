variable "location" {
  description = "Azure region for the Virtual Hub."
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Resource group name to create for this hub stack."
  type        = string
  default     = "msft-vhub-prod-rg"
}

variable "virtual_hub_name" {
  description = "Name of the Virtual Hub."
  type        = string
  default     = "msft-vhub-prod"
}

variable "hub_address_prefix" {
  description = "Address prefix for the hub (CIDR)."
  type        = string
  default     = "10.2.0.0/16"
}

variable "firewall_name" {
  description = "Name for the Azure Firewall deployed into the secured vHub."
  type        = string
  default     = "msft-vhub-prod-firewall"
}

variable "enable_module_telemetry" {
  description = "Enable AVM module telemetry."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default = {
    environment = "prod"
    workload    = "msft-vhub"
  }
}
