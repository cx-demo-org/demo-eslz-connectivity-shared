locals {
  gateway_id = try(
    module.this.resource_id["gateway"],
    module.this.resource_id[0]
  )

  gateway_name = try(
    module.this.resource["gateway"],
    module.this.resource[0]
  )

  gateway_object = try(
    module.this.resource_object["gateway"],
    module.this.resource_object[0]
  )
}

output "id" {
  description = "ExpressRoute Gateway resource ID."
  value       = local.gateway_id
}

output "name" {
  description = "ExpressRoute Gateway resource name."
  value       = local.gateway_name
}

output "resource_object" {
  description = "ExpressRoute Gateway resource object."
  value       = local.gateway_object
}
