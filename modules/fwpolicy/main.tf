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

resource "azurerm_firewall_policy" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "custom" {
  for_each = local.rule_collection_groups_effective

  name               = each.key
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = each.value.priority

  dynamic "application_rule_collection" {
    for_each = try(tomap(try(each.value.application_rule_collections, {})), {})
    content {
      name     = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = can(application_rule_collection.value.rules[0]) ? application_rule_collection.value.rules : [
          for rule_name, rule_obj in application_rule_collection.value.rules : merge(rule_obj, { name = rule_name })
        ]
        content {
          name             = rule.value.name
          source_addresses = rule.value.source_addresses

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }

          destination_fqdns     = try(rule.value.destination_fqdns, null)
          destination_fqdn_tags = try(rule.value.destination_fqdn_tags, null)
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = try(tomap(try(each.value.network_rule_collections, {})), {})
    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = can(network_rule_collection.value.rules[0]) ? network_rule_collection.value.rules : [
          for rule_name, rule_obj in network_rule_collection.value.rules : merge(rule_obj, { name = rule_name })
        ]
        content {
          name              = rule.value.name
          protocols         = rule.value.protocols
          source_addresses  = rule.value.source_addresses
          destination_ports = rule.value.destination_ports

          destination_addresses = try(rule.value.destination_addresses, null)
          destination_fqdns     = try(rule.value.destination_fqdns, null)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = local.aks_builtin_enabled == false || length(local.aks_source_addresses) > 0
      error_message = "When builtins.aks_egress.enabled=true, builtins.aks_egress.source_addresses must be provided and non-empty."
    }

    precondition {
      condition     = local.aks_builtin_enabled == false || (length(local.aks_dns_servers) > 0 && length(local.aks_ntp_servers) > 0)
      error_message = "When builtins.aks_egress.enabled=true, builtins.aks_egress.dns_servers and builtins.aks_egress.ntp_servers must be provided and non-empty."
    }
  }
}

