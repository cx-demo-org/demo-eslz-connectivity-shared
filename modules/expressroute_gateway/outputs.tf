output "id" {
  description = "ExpressRoute Gateway resource ID."
  value       = module.this.resource_id[0]
}

output "name" {
  description = "ExpressRoute Gateway resource name."
  value       = module.this.resource[0]
}

output "resource_object" {
  description = "ExpressRoute Gateway resource object."
  value       = module.this.resource_object[0]
}
