resource "azurerm_firewall_policy" "this" {
  name                = var.firewall_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  tags = var.tags
}

# Baseline placeholder rule collection group.
resource "azurerm_firewall_policy_rule_collection_group" "baseline" {
  name               = "baseline"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 500
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
        type = "Https"
        port = 443
      }

      destination_fqdns = var.aks_egress_fqdns
    }
  }

  network_rule_collection {
    name     = "aks-network"
    priority = 210
    action   = "Allow"

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
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = var.aks_egress_network_allow.ntp_servers
      destination_ports     = ["123"]
    }

    # Generic HTTPS egress
    rule {
      name                  = "https-tcp"
      protocols             = ["TCP"]
      source_addresses      = var.aks_egress_source_addresses
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["443"]
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
