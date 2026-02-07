variable "name" {
  description = "ExpressRoute Circuit name."
  type        = string
}

variable "location" {
  description = "Azure region for the ExpressRoute Circuit."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the ExpressRoute Circuit will be created."
  type        = string
}

variable "sku" {
  description = "ExpressRoute Circuit SKU."
  type = object({
    tier   = string
    family = string
  })
}

variable "tags" {
  description = "Tags applied to resources created by the module."
  type        = map(string)
  default     = null
}

variable "exr_circuit_tags" {
  description = "Optional tags applied specifically to the ExpressRoute Circuit resource."
  type        = map(string)
  default     = null
}

variable "service_provider_name" {
  description = "ExpressRoute service provider name (when using provider-based circuits)."
  type        = string
  default     = null
}

variable "peering_location" {
  description = "Peering location name (not the Azure resource location)."
  type        = string
  default     = null
}

variable "bandwidth_in_mbps" {
  description = "Bandwidth in Mbps (provider-based circuits)."
  type        = number
  default     = null
}

variable "bandwidth_in_gbps" {
  description = "Bandwidth in Gbps (ExpressRoute Direct circuits)."
  type        = number
  default     = null
}

variable "allow_classic_operations" {
  description = "Allow the circuit to interact with classic resources."
  type        = bool
  default     = false
}

variable "authorization_key" {
  description = "Optional authorization key for creating a circuit with an ExpressRoute Port from another subscription."
  type        = string
  default     = null
}

variable "express_route_port_resource_id" {
  description = "Optional ExpressRoute Port resource ID (ExpressRoute Direct)."
  type        = string
  default     = null
}

variable "peerings" {
  description = "Optional map of peering configurations. See the AVM module inputs for schema."
  type        = any
  default     = {}
}

variable "express_route_circuit_authorizations" {
  description = "Optional map of authorizations to create."
  type        = any
  default     = {}
}

variable "er_gw_connections" {
  description = "Optional map of ExpressRoute Gateway connections (Virtual WAN)."
  type        = any
  default     = {}
}

variable "vnet_gw_connections" {
  description = "Optional map of Virtual Network Gateway connections."
  type        = any
  default     = {}
}

variable "circuit_connections" {
  description = "Optional map of circuit-to-circuit (Global Reach) connections."
  type        = any
  default     = {}
}

variable "diagnostic_settings" {
  description = "Optional diagnostic settings."
  type        = any
  default     = {}
}

variable "role_assignments" {
  description = "Optional role assignments."
  type        = any
  default     = {}
}

variable "lock" {
  description = "Optional resource lock configuration."
  type        = any
  default     = null
}

variable "enable_telemetry" {
  description = "Enable AVM module telemetry."
  type        = bool
  default     = true
}
