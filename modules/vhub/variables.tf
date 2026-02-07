variable "name" {
  description = "Virtual Hub name."
  type        = string
}

variable "location" {
  description = "Azure region for the Virtual Hub."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the Virtual Hub will be created."
  type        = string
}

variable "address_prefix" {
  description = "Address prefix for the hub (CIDR)."
  type        = string
}

variable "virtual_wan_id" {
  description = "Resource ID of the Virtual WAN to attach this hub to."
  type        = string
}

variable "tags" {
  description = "Tags applied to hub resources."
  type        = map(string)
  default     = {}
}

variable "create_firewall" {
  description = "If true, deploy an Azure Firewall into the vHub (secured hub)."
  type        = bool
  default     = false
}

variable "firewall_name" {
  description = "Name of the Azure Firewall (only used when create_firewall=true)."
  type        = string
  default     = null
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier (Standard/Premium)."
  type        = string
  default     = "Standard"
}

variable "firewall_policy_id" {
  description = "Firewall Policy resource ID to attach to the firewall (only used when create_firewall=true)."
  type        = string
  default     = null
}

variable "firewall_extra_tags" {
  description = "Additional tags to apply to the firewall."
  type        = map(string)
  default     = {}
}
