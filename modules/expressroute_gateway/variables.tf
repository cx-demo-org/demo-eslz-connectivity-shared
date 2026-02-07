variable "name" {
  description = "ExpressRoute Gateway name."
  type        = string
}

variable "location" {
  description = "Azure region for the ExpressRoute Gateway."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the ExpressRoute Gateway will be created."
  type        = string
}

variable "virtual_hub_id" {
  description = "Resource ID of the Virtual Hub to deploy the ExpressRoute Gateway into."
  type        = string
}

variable "tags" {
  description = "Tags applied to the ExpressRoute Gateway resource."
  type        = map(string)
  default     = {}
}

variable "allow_non_virtual_wan_traffic" {
  description = "Whether the gateway accepts traffic from non-Virtual WAN networks."
  type        = bool
  default     = false
}

variable "scale_units" {
  description = "ExpressRoute Gateway scale units."
  type        = number
  default     = 1

  validation {
    condition     = var.scale_units >= 1
    error_message = "scale_units must be >= 1."
  }
}
