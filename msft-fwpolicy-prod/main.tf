locals {
  aks_control_plane_service_tag = "AzureCloud.${var.location}"
  aks_egress_fqdns_computed = [
    "*.hcp.${var.location}.azmk8s.io",
    "${var.location}.handler.control.monitor.azure.com",
    "${var.location}.dp.kubernetesconfiguration.azure.com",
  ]
}

resource "azurerm_firewall_policy" "this" {
  name                = var.firewall_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "aks_egress" {
  name               = "aks-egress"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  application_rule_collection {
    name     = "aks-app"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks-platform-fqdns"

      source_addresses = var.aks_egress_source_addresses

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = distinct(concat(var.aks_egress_fqdns, local.aks_egress_fqdns_computed))
    }

    rule {
      name = "aks-fqdn-tag"

      source_addresses = var.aks_egress_source_addresses

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdn_tags = ["AzureKubernetesService"]
    }
  }

  network_rule_collection {
    name     = "aks-network"
    priority = 210
    action   = "Allow"

    # AKS control plane tunnel ports (required for non-private clusters without konnectivity).
    rule {
      name                  = "aks-controlplane-udp-1194"
      protocols             = ["UDP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = [local.aks_control_plane_service_tag]
      destination_ports     = ["1194"]
    }

    rule {
      name                  = "aks-controlplane-tcp-9000"
      protocols             = ["TCP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = [local.aks_control_plane_service_tag]
      destination_ports     = ["9000"]
    }

    # DNS
    rule {
      name                  = "dns-udp"
      protocols             = ["UDP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = var.aks_egress_network_allow.dns_servers
      destination_ports     = ["53"]
    }

    rule {
      name                  = "dns-tcp"
      protocols             = ["TCP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = var.aks_egress_network_allow.dns_servers
      destination_ports     = ["53"]
    }

    # NTP
    rule {
      name                  = "ntp-udp"
      protocols             = ["UDP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = var.aks_egress_network_allow.ntp_servers
      destination_ports     = ["123"]
    }

    # Optional extra TCP/443 destinations expressed as FQDNs (if you prefer network rules).
    dynamic "rule" {
      for_each = length(var.aks_egress_network_allow.extra_tcp_fqdns) > 0 ? [1] : []
      content {
        name              = "extra-tcp-443"
        protocols         = ["TCP"]
        source_addresses  = var.aks_egress_source_addresses
        destination_fqdns = var.aks_egress_network_allow.extra_tcp_fqdns
        destination_ports = ["443"]
      }
    }
  }
}
