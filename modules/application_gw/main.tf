locals {
  waf_policy_ids = { for k, v in module.waf_policy : k => v.resource_id }
}

module "waf_policy" {
  for_each = var.web_application_firewall_policies

  source  = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version = "0.2.0"

  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  location            = coalesce(try(each.value.location, null), try(each.value.region, null), null)

  # This AVM module requires managed_rules. Provide a safe default when omitted.
  managed_rules = coalesce(
    try(each.value.managed_rules, null),
    {
      managed_rule_set = {
        owasp_3_2 = {
          type    = "OWASP"
          version = "3.2"
        }
      }
    }
  )

  custom_rules     = try(each.value.custom_rules, null)
  policy_settings  = try(each.value.policy_settings, null)
  role_assignments = try(each.value.role_assignments, {})
  lock             = try(each.value.lock, null)
  tags             = try(each.value.tags, null)
  timeouts         = try(each.value.timeouts, null)

  enable_telemetry = var.enable_telemetry
}

module "appgw" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.5.2"

  for_each = var.application_gateways

  name                = each.value.name
  location            = each.value.location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  gateway_ip_configuration = {
    name      = try(each.value.gateway_ip_configuration_name, null)
    subnet_id = var.virtual_networks[each.value.virtual_network_key].subnets[each.value.subnet_key].resource_id
  }

  backend_address_pools = each.value.backend_address_pools
  backend_http_settings = each.value.backend_http_settings
  frontend_ports        = each.value.frontend_ports
  http_listeners        = each.value.http_listeners
  request_routing_rules = each.value.request_routing_rules

  # AVM optional inputs (pass-through)
  app_gateway_waf_policy_resource_id = coalesce(
    try(each.value.app_gateway_waf_policy_resource_id, null),
    try(each.value.waf_policy_key, null) != null ? try(local.waf_policy_ids[each.value.waf_policy_key], null) : null
  )
  authentication_certificate            = try(each.value.authentication_certificate, null)
  autoscale_configuration               = try(each.value.autoscale_configuration, null)
  custom_error_configuration            = try(each.value.custom_error_configuration, null)
  diagnostic_settings                   = try(each.value.diagnostic_settings, {})
  enable_telemetry                      = var.enable_telemetry
  fips_enabled                          = try(each.value.fips_enabled, null)
  force_firewall_policy_association     = try(each.value.force_firewall_policy_association, true)
  frontend_ip_configuration_private     = try(each.value.frontend_ip_configuration_private, {})
  frontend_ip_configuration_public_name = try(each.value.frontend_ip_configuration_public_name, null)
  global                                = try(each.value.global, null)
  http2_enable                          = try(each.value.http2_enable, true)
  lock                                  = try(each.value.lock, null)
  managed_identities                    = try(each.value.managed_identities, {})
  private_link_configuration            = try(each.value.private_link_configuration, null)
  probe_configurations                  = try(each.value.probe_configurations, null)
  public_ip_address_configuration       = try(each.value.public_ip_address_configuration, {})
  redirect_configuration                = try(each.value.redirect_configuration, null)
  rewrite_rule_set                      = try(each.value.rewrite_rule_set, null)
  role_assignments                      = try(each.value.role_assignments, {})
  sku                                   = try(each.value.sku, null)
  ssl_certificates                      = try(each.value.ssl_certificates, null)
  ssl_policy                            = try(each.value.ssl_policy, null)
  ssl_profile                           = try(each.value.ssl_profile, null)
  timeouts                              = try(each.value.timeouts, null)
  trusted_client_certificate            = try(each.value.trusted_client_certificate, null)
  trusted_root_certificate              = try(each.value.trusted_root_certificate, null)
  url_path_map_configurations           = try(each.value.url_path_map_configurations, null)
  waf_configuration                     = try(each.value.waf_configuration, null)
  # IMPORTANT: don't pass null here. The upstream module uses coalesce() and errors when both
  # public_ip_address_configuration.zones and zones are null.
  zones = try(toset(each.value.zones), toset(["1", "2", "3"]))

  tags = try(each.value.tags, null)
}
