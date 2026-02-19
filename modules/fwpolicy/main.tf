locals {
  aks_control_plane_service_tag = "AzureCloud.${var.location}"
  aks_egress_fqdns_computed = [
    "*.hcp.${var.location}.azmk8s.io",
    "${var.location}.handler.control.monitor.azure.com",
    "${var.location}.dp.kubernetesconfiguration.azure.com",
  ]

  aks_builtin_enabled = try(var.builtins.aks_egress.enabled, false)

  aks_source_addresses = try(var.builtins.aks_egress.source_addresses, [])
  aks_egress_fqdns = distinct(concat(
    try(var.builtins.aks_egress.additional_fqdns, []),
    local.aks_egress_fqdns_computed
  ))
  aks_dns_servers     = try(var.builtins.aks_egress.dns_servers, [])
  aks_ntp_servers     = try(var.builtins.aks_egress.ntp_servers, [])
  aks_extra_tcp_fqdns = try(var.builtins.aks_egress.extra_tcp_fqdns, [])

  aks_rule_collection_groups = local.aks_builtin_enabled ? {
    "aks-egress" = {
      priority = 200

      application_rule_collections = {
        "aks-app" = {
          priority = 200
          action   = "Allow"
          rules = {
            "aks-platform-fqdns" = {
              source_addresses = local.aks_source_addresses
              protocols = [
                { type = "Http", port = 80 },
                { type = "Https", port = 443 },
              ]
              destination_fqdns = local.aks_egress_fqdns
            }

            "aks-fqdn-tag" = {
              source_addresses = local.aks_source_addresses
              protocols = [
                { type = "Http", port = 80 },
                { type = "Https", port = 443 },
              ]
              destination_fqdn_tags = ["AzureKubernetesService"]
            }
          }
        }
      }

      network_rule_collections = {
        "aks-network" = {
          priority = 210
          action   = "Allow"
          rules = merge(
            {
              "aks-controlplane-udp-1194" = {
                protocols             = ["UDP"]
                source_addresses      = local.aks_source_addresses
                destination_addresses = [local.aks_control_plane_service_tag]
                destination_ports     = ["1194"]
              }

              "aks-controlplane-tcp-9000" = {
                protocols             = ["TCP"]
                source_addresses      = local.aks_source_addresses
                destination_addresses = [local.aks_control_plane_service_tag]
                destination_ports     = ["9000"]
              }

              "dns-udp" = {
                protocols             = ["UDP"]
                source_addresses      = local.aks_source_addresses
                destination_addresses = local.aks_dns_servers
                destination_ports     = ["53"]
              }

              "dns-tcp" = {
                protocols             = ["TCP"]
                source_addresses      = local.aks_source_addresses
                destination_addresses = local.aks_dns_servers
                destination_ports     = ["53"]
              }

              "ntp-udp" = {
                protocols             = ["UDP"]
                source_addresses      = local.aks_source_addresses
                destination_addresses = local.aks_ntp_servers
                destination_ports     = ["123"]
              }
            },
            length(local.aks_extra_tcp_fqdns) > 0 ? {
              "extra-tcp-443" = {
                protocols         = ["TCP"]
                source_addresses  = local.aks_source_addresses
                destination_fqdns = local.aks_extra_tcp_fqdns
                destination_ports = ["443"]
              }
            } : {}
          )
        }
      }
    }
  } : {}

  rule_collection_groups_custom    = try(tomap(var.rule_collection_groups), {})
  rule_collection_groups_effective = merge(local.aks_rule_collection_groups, local.rule_collection_groups_custom)
}

locals {
  rule_collection_groups_application_rule_collections = {
    for group_name, group in local.rule_collection_groups_effective : group_name => [
      for collection_name, collection in try(tomap(try(group.application_rule_collections, {})), {}) : {
        action   = collection.action
        name     = collection_name
        priority = collection.priority
        rule = [
          for r in(
            can(collection.rules[0]) ? collection.rules : [
              for rule_name, rule_obj in collection.rules : merge(rule_obj, { name = rule_name })
            ]
            ) : {
            name                  = r.name
            description           = try(r.description, null)
            source_addresses      = try(r.source_addresses, [])
            source_ip_groups      = try(r.source_ip_groups, [])
            destination_addresses = try(r.destination_addresses, [])
            destination_fqdn_tags = try(r.destination_fqdn_tags, [])
            destination_fqdns     = try(r.destination_fqdns, [])
            destination_urls      = try(r.destination_urls, [])
            web_categories        = try(r.web_categories, [])
            terminate_tls         = try(r.terminate_tls, null)
            http_headers          = try(r.http_headers, null)
            protocols             = try(r.protocols, null)
          }
        ]
      }
    ]
  }

  rule_collection_groups_network_rule_collections = {
    for group_name, group in local.rule_collection_groups_effective : group_name => [
      for collection_name, collection in try(tomap(try(group.network_rule_collections, {})), {}) : {
        action   = collection.action
        name     = collection_name
        priority = collection.priority
        rule = [
          for r in(
            can(collection.rules[0]) ? collection.rules : [
              for rule_name, rule_obj in collection.rules : merge(rule_obj, { name = rule_name })
            ]
            ) : {
            name                  = r.name
            description           = try(r.description, null)
            protocols             = r.protocols
            source_addresses      = try(r.source_addresses, [])
            source_ip_groups      = try(r.source_ip_groups, [])
            destination_addresses = try(r.destination_addresses, [])
            destination_fqdns     = try(r.destination_fqdns, [])
            destination_ip_groups = try(r.destination_ip_groups, [])
            destination_ports     = r.destination_ports
          }
        ]
      }
    ]
  }
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  firewall_policy_sku = "Standard"
  tags                = var.tags

  enable_telemetry = false
}

module "rule_collection_groups" {
  for_each = local.rule_collection_groups_effective

  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.4"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource_id
  firewall_policy_rule_collection_group_name               = each.key
  firewall_policy_rule_collection_group_priority           = each.value.priority

  firewall_policy_rule_collection_group_application_rule_collection = length(local.rule_collection_groups_application_rule_collections[each.key]) > 0 ? local.rule_collection_groups_application_rule_collections[each.key] : null
  firewall_policy_rule_collection_group_network_rule_collection     = length(local.rule_collection_groups_network_rule_collections[each.key]) > 0 ? local.rule_collection_groups_network_rule_collections[each.key] : null
  firewall_policy_rule_collection_group_nat_rule_collection         = null
}

moved {
  from = azurerm_firewall_policy.this
  to   = module.firewall_policy.azurerm_firewall_policy.this
}

