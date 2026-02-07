output "resource_id" {
  description = "ExpressRoute Circuit resource ID."
  value       = module.this.resource_id
}

output "name" {
  description = "ExpressRoute Circuit name."
  value       = module.this.name
}

output "authorization_keys" {
  description = "Authorization keys for the circuit (if configured)."
  value       = module.this.authorization_keys
}

output "peerings" {
  description = "Peerings created for the circuit (if configured)."
  value       = module.this.peerings
}

output "express_route_gateway_connections" {
  description = "ExpressRoute gateway connections (if configured)."
  value       = module.this.express_route_gateway_connections
}
