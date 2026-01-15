variable "location" {
  description = "Default location required by the AVM ALZ module for some resources/identities."
  type        = string
  default     = "southeastasia"
}

variable "parent_resource_id" {
  description = "Parent resource for the ALZ architecture. Use the tenant GUID to deploy under tenant root."
  type        = string
  default     = null
}

# AVM examples use "alz" for the default reference architecture.
variable "architecture_name" {
  description = "Architecture name to deploy (e.g., 'alz')."
  type        = string
  default     = "alz"
}
