output "web_application_firewall_policy_ids" {
  description = "Map of WAF policy IDs by key."
  value       = local.waf_policy_ids
}

output "application_gateway_ids" {
  description = "Map of Application Gateway IDs by key."
  value       = { for k, v in module.appgw : k => v.application_gateway_id }
}

output "application_gateway_public_ip_ids" {
  description = "Map of Public IP resource IDs (when created/used by AppGW) by key."
  value       = { for k, v in module.appgw : k => try(v.public_ip_id, null) }
}

output "application_gateway_public_ip_addresses" {
  description = "Map of Public IP addresses (when created by AppGW) by key."
  value       = { for k, v in module.appgw : k => try(v.new_public_ip_address, null) }
}
