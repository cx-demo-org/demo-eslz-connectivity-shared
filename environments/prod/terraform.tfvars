###############################################
# Resource groups
#
# This section defines the resource groups this environment will create and
# then reference from other blocks (vWAN, vHub, firewall policy, ExpressRoute).
#
# Key = internal handle used by `resource_group_key` references.
###############################################
resource_groups = {
  ###############################################
  # Southeast Asia (southeastasia)
  ###############################################
  prod_connectivity = {
    name     = "msft-prod-connectivity-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "msft-vwan"
    }
  }

  prod_hub = {
    name     = "msft-connectivity-prod-sea-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "msft-vhub"
    }
  }

  ###############################################
  # Europe (westeurope)
  ###############################################
  prod_hub_eu = {
    name     = "msft-connectivity-prod-eu-rg"
    location = "westeurope"
    tags = {
      environment = "prod"
      workload    = "msft-vhub"
    }
  }
}

###############################################
# Subscription / tenant targeting
#
# These IDs control where resources are created/looked up.
# - Hub subscription: vHub, Azure Firewall, Firewall Policy, ExpressRoute.
# - vWAN subscription: vWAN create/lookup (prod owns the shared vWAN).
###############################################
# Target subscription/tenant for hub resources (vHub, Azure Firewall, Firewall Policy, etc.)
hub_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
hub_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

# vWAN subscription/tenant (prod owns/creates the vWAN in this state).
virtual_wan_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
virtual_wan_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

###############################################
# Virtual WAN (vWAN)
#
# Prod is the “source of truth” for the shared vWAN.
# If the vWAN already exists, either import it into this env state, or switch
# to lookup mode (see notes below).
###############################################
# In the target design, vWAN is created once (here in prod).
# If the vWAN already exists, either:
# - import it into this env state, or
# - set create=false and supply resource_group_name to data-lookup instead.
virtual_wan = {
  name               = "msft-prod-sea-vwan"
  resource_group_key = "prod_connectivity"
  location           = "southeastasia"
  sku                = "Standard"

  enable_module_telemetry = false

  allow_branch_to_branch_traffic = true
  disable_vpn_encryption         = false

  tags = {
    environment = "prod"
    workload    = "msft-vwan"
  }
}

###############################################
# ExpressRoute circuits (optional)
#
# Circuits often require coordination with your service provider:
# 1) Create the circuit (no peerings/connections)
# 2) Share the service key with the provider and wait for Provisioned
# 3) Add peerings and/or ER gateway connections afterwards
###############################################
# ExpressRoute circuits (optional).
# Note: Circuits usually require coordination with your service provider.
# It’s common to:
# 1) Create the circuit first (without peerings/connections),
# 2) Share the service key with the provider, then
# 3) Add peerings/connections only after the circuit is provisioned.
# ExpressRoute circuits are optional. Keep this empty by default.
#
# ExpressRoute circuits (optional).
# If a circuit already exists and is in state, keep it defined here to avoid destroy.
expressroute_circuits = {
  prod_primary = {
    # ExpressRoute circuit: msft-prod-sea-er-circuit-01
    name               = "msft-prod-sea-er-circuit-01"
    resource_group_key = "prod_hub"
    location           = "southeastasia"

    sku = {
      tier   = "Premium"
      family = "MeteredData"
    }

    service_provider_name = "SingTel Domestic"
    peering_location      = "Singapore"

    # 1Gbps
    bandwidth_in_mbps = 1000

    enable_telemetry = false

    tags = {
      environment = "prod"
      workload    = "msft-expressroute"
    }
  }
}

###############################################
# Azure Firewall Policy + rules
#
# This section defines firewall policies and rule collection groups.
# Rules are tfvars-driven to make egress/allow-lists easy to customize.
###############################################
firewall_policies = {
  ###############################################
  # Southeast Asia (southeastasia)
  ###############################################
  prod = {
    name               = "msft-vhub-prod-sea-firewall-policy"
    resource_group_key = "prod_hub"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "msft-fwpolicy"
    }

    # Rules are explicitly managed via tfvars so end users can customize them.
    rule_collection_groups = {
      "aks-egress" = {
        priority = 200

        application_rule_collections = {
          "aks-app" = {
            priority = 200
            action   = "Allow"

            rules = [
              {
                name             = "aks-platform-fqdns"
                source_addresses = ["*"]
                protocols        = [{ type = "Http", port = 80 }, { type = "Https", port = 443 }]
                destination_fqdns = [
                  "*.azmk8s.io",
                  "mcr.microsoft.com",
                  "*.data.mcr.microsoft.com",
                  "mcr-0001.mcr-msedge.net",
                  "*.cdn.mscr.io",
                  "*.blob.core.windows.net",
                  "archive.ubuntu.com",
                  "security.ubuntu.com",
                  "azure.archive.ubuntu.com",
                  "packages.microsoft.com",
                  "download.microsoft.com",
                  "management.azure.com",
                  "login.microsoftonline.com",
                  "graph.microsoft.com",
                  "acs-mirror.azureedge.net",
                  "packages.aks.azure.com",
                  "*.ods.opinsights.azure.com",
                  "*.oms.opinsights.azure.com",
                  "*.monitoring.azure.com",
                  "dc.services.visualstudio.com",
                  "*.in.applicationinsights.azure.com",
                  "global.handler.control.monitor.azure.com",
                  "*.handler.control.monitor.azure.com",
                  "*.ingest.monitor.azure.com",
                  "*.metrics.ingest.monitor.azure.com",
                  "data.policy.core.windows.net",
                  "store.policy.core.windows.net",
                  "*.securitycenter.windows.com",
                  "*.cloud.defender.microsoft.com",
                  "*.hcp.southeastasia.azmk8s.io",
                  "*.microsoft.com",
                  "southeastasia.handler.control.monitor.azure.com",
                  "southeastasia.dp.kubernetesconfiguration.azure.com",
                ]
              },
              {
                name                  = "aks-fqdn-tag"
                source_addresses      = ["*"]
                protocols             = [{ type = "Http", port = 80 }, { type = "Https", port = 443 }]
                destination_fqdn_tags = ["AzureKubernetesService"]
              },
            ]
          }
        }

        network_rule_collections = {
          "aks-network" = {
            priority = 210
            action   = "Allow"

            rules = [
              {
                name                  = "aks-controlplane-udp-1194"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["AzureCloud.southeastasia"]
                destination_ports     = ["1194"]
              },
              {
                name                  = "aks-controlplane-tcp-9000"
                protocols             = ["TCP"]
                source_addresses      = ["*"]
                destination_addresses = ["AzureCloud.southeastasia"]
                destination_ports     = ["9000"]
              },
              {
                name                  = "dns-udp"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["53"]
              },
              {
                name                  = "dns-tcp"
                protocols             = ["TCP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["53"]
              },
              {
                name                  = "ntp-udp"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["123"]
              },
            ]
          }
        }
      }
    }
  }

  ###############################################
  # Europe (westeurope)
  ###############################################
  prod_eu = {
    name               = "msft-vhub-prod-eu-firewall-policy"
    resource_group_key = "prod_hub_eu"
    location           = "westeurope"
    tags = {
      environment = "prod"
      workload    = "msft-fwpolicy"
    }

    # Start with the same baseline allow-list as SEA, then tailor as needed.
    rule_collection_groups = {
      "aks-egress" = {
        priority = 200

        application_rule_collections = {
          "aks-app" = {
            priority = 200
            action   = "Allow"

            rules = [
              {
                name             = "aks-platform-fqdns"
                source_addresses = ["*"]
                protocols        = [{ type = "Http", port = 80 }, { type = "Https", port = 443 }]
                destination_fqdns = [
                  "*.azmk8s.io",
                  "mcr.microsoft.com",
                  "*.data.mcr.microsoft.com",
                  "mcr-0001.mcr-msedge.net",
                  "*.cdn.mscr.io",
                  "*.blob.core.windows.net",
                  "archive.ubuntu.com",
                  "security.ubuntu.com",
                  "azure.archive.ubuntu.com",
                  "packages.microsoft.com",
                  "download.microsoft.com",
                  "management.azure.com",
                  "login.microsoftonline.com",
                  "graph.microsoft.com",
                  "acs-mirror.azureedge.net",
                  "packages.aks.azure.com",
                  "*.ods.opinsights.azure.com",
                  "*.oms.opinsights.azure.com",
                  "*.monitoring.azure.com",
                  "dc.services.visualstudio.com",
                  "*.in.applicationinsights.azure.com",
                  "global.handler.control.monitor.azure.com",
                  "*.handler.control.monitor.azure.com",
                  "*.ingest.monitor.azure.com",
                  "*.metrics.ingest.monitor.azure.com",
                  "data.policy.core.windows.net",
                  "store.policy.core.windows.net",
                  "*.securitycenter.windows.com",
                  "*.cloud.defender.microsoft.com",
                ]
              },
              {
                name                  = "aks-fqdn-tag"
                source_addresses      = ["*"]
                protocols             = [{ type = "Http", port = 80 }, { type = "Https", port = 443 }]
                destination_fqdn_tags = ["AzureKubernetesService"]
              },
            ]
          }
        }

        network_rule_collections = {
          "aks-network" = {
            priority = 210
            action   = "Allow"

            rules = [
              {
                name                  = "aks-controlplane-udp-1194"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["AzureCloud.westeurope"]
                destination_ports     = ["1194"]
              },
              {
                name                  = "aks-controlplane-tcp-9000"
                protocols             = ["TCP"]
                source_addresses      = ["*"]
                destination_addresses = ["AzureCloud.westeurope"]
                destination_ports     = ["9000"]
              },
              {
                name                  = "dns-udp"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["53"]
              },
              {
                name                  = "dns-tcp"
                protocols             = ["TCP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["53"]
              },
              {
                name                  = "ntp-udp"
                protocols             = ["UDP"]
                source_addresses      = ["*"]
                destination_addresses = ["*"]
                destination_ports     = ["123"]
              },
            ]
          }
        }
      }
    }
  }
}

###############################################
# Virtual hubs (vHubs)
#
# Defines the vHub(s) for this environment and optionally attaches:
# - Azure Firewall (Hub SKU)
# - ExpressRoute gateway (Virtual WAN gateway inside the vHub)
###############################################
virtual_hubs = {
  ###############################################
  # Southeast Asia (southeastasia)
  ###############################################
  prod = {
    name               = "msft-vhub-prod-sea"
    resource_group_key = "prod_hub"
    location           = "southeastasia"
    address_prefix     = "10.2.0.0/20"

    tags = {
      environment = "prod"
      workload    = "msft-vhub"
    }

    firewall = {
      name                = "msft-vhub-prod-sea-firewall"
      firewall_policy_key = "prod"
    }

    expressroute_gateway = {
      name        = "msft-vhub-prod-sea-ergw"
      scale_units = 1
    }

    # Optional: Site-to-Site VPN (S2S VPN Gateway + VPN Site + Connection)
    #
    # Keep vpn_site_connections empty until the on-prem shared key is available.
    site_to_site_vpn = {
      vpn_gateways = {
        prod = {
          # Site-to-site VPN gateway: msft-vhub-prod-sea-s2s-gw
          name       = "msft-vhub-prod-sea-s2s-gw"
          scale_unit = 1
        }
      }

      vpn_sites = {
        prod = {
          name          = "msft-prod-vpn-site"
          address_cidrs = ["10.100.0.0/24"]
          links = [
            {
              name       = "prod-link-1"
              ip_address = "203.0.113.10"
            }
          ]
        }
      }

      vpn_site_connections = {}
    }

    # Optional: Private DNS Resolver (creates sidecar VNet + vHub connection + resolver)
    private_dns_resolver = {
      # resource_group_key = "prod_dns"  # optional: separate RG key for DNS resources
      name = "msft-pdr-prod-sea"

      sidecar_virtual_network = {
        name          = "msft-vnet-prod-sea-dns"
        address_space = ["10.2.16.0/24"]
      }

      inbound_subnet = {
        address_prefixes = ["10.2.16.0/28"]
        network_security_group = {
          id = "/subscriptions/2f69b2b1-5fe0-487d-8c82-52f5edeb454e/resourceGroups/msft-connectivity-prod-sea-rg/providers/Microsoft.Network/networkSecurityGroups/msft-vnet-prod-sea-dns-dns-inbound-nsg-southeastasia"
        }
      }

      outbound_subnet = {
        address_prefixes = ["10.2.16.16/28"]
        network_security_group = {
          id = "/subscriptions/2f69b2b1-5fe0-487d-8c82-52f5edeb454e/resourceGroups/msft-connectivity-prod-sea-rg/providers/Microsoft.Network/networkSecurityGroups/msft-vnet-prod-sea-dns-dns-outbound-nsg-southeastasia"
        }
      }

      outbound_endpoints = {
        default = {}
      }

      # Optional: DNS forwarding ruleset (hybrid/on-prem)
      #
      # Enabled by default for prod SEA and prod EU so both hubs have
      # consistent DNS forwarding behavior.
      #
      # Update the domain and target DNS server IPs to match your environment.
      #
      # Note: if forwarding_rulesets is configured, keep exactly ONE outbound_endpoints entry.
      #
      forwarding_rulesets = {
        default = {
          # DNS forwarding ruleset: ruleset-default-default
          name = "ruleset-default-default"

          rules = {
            corp = {
              domain_name = "corp.contoso.com."
              target_dns_servers = [
                { ip_address = "10.0.0.10", port = 53 },
                { ip_address = "10.0.0.11", port = 53 },
              ]
            }
          }
        }
      }
    }

    # Private DNS Zones for Private Endpoints
    # Uses the AVM module's built-in zone catalog (Microsoft Learn list).
    # EU hub will, by default, only create the regional zones ({regionName}/{regionCode}).
    private_dns_zones = {
      auto_registration_zone_enabled = false
    }
  }

  ###############################################
  # Europe (westeurope)
  ###############################################
  prod_eu = {
    name               = "msft-vhub-prod-eu"
    resource_group_key = "prod_hub_eu"
    location           = "westeurope"
    address_prefix     = "172.16.0.0/20"

    tags = {
      environment = "prod"
      workload    = "msft-vhub"
    }

    firewall = {
      name                = "msft-vhub-prod-eu-firewall"
      firewall_policy_key = "prod_eu"
    }

    expressroute_gateway = {
      name        = "msft-vhub-prod-eu-ergw"
      scale_units = 1
    }

    # Optional: Site-to-Site VPN (S2S VPN Gateway + VPN Site + Connection)
    #
    # Placeholder (disabled by default). To create an S2S gateway named
    # `msft-vhub-prod-eu-s2s-gw`, uncomment the block below and replace the
    # sample on-prem details.
    #
    # site_to_site_vpn = {
    #   vpn_gateways = {
    #     prod = {
    #       # Site-to-site VPN gateway: msft-vhub-prod-eu-s2s-gw
    #       name       = "msft-vhub-prod-eu-s2s-gw"
    #       scale_unit = 1
    #     }
    #   }
    #
    #   vpn_sites = {
    #     prod = {
    #       name          = "msft-prod-eu-vpn-site"
    #       address_cidrs = ["10.100.0.0/24"]
    #       links = [
    #         {
    #           name       = "prod-link-1"
    #           ip_address = "203.0.113.10"
    #         }
    #       ]
    #     }
    #   }
    #
    #   vpn_site_connections = {
    #     # prod = {
    #     #   name            = "msft-vhub-prod-eu-to-onprem"
    #     #   vpn_gateway_key = "prod"
    #     #   vpn_site_key    = "prod"
    #     #
    #     #   vpn_links = [
    #     #     {
    #     #       name               = "prod-link-1"
    #     #       vpn_site_link_name = "prod-link-1"
    #     #       shared_key         = "REPLACE_ME"
    #     #     }
    #     #   ]
    #     # }
    #   }
    # }

    # Optional: Private DNS Resolver (creates sidecar VNet + vHub connection + resolver)
    private_dns_resolver = {
      # resource_group_key = "prod_dns_eu"  # optional: separate RG key for DNS resources
      name = "msft-pdr-prod-eu"

      sidecar_virtual_network = {
        name          = "msft-vnet-prod-eu-dns"
        address_space = ["172.16.16.0/24"]
      }

      inbound_subnet = {
        address_prefixes = ["172.16.16.0/28"]
        network_security_group = {
          id = "/subscriptions/2f69b2b1-5fe0-487d-8c82-52f5edeb454e/resourceGroups/msft-connectivity-prod-eu-rg/providers/Microsoft.Network/networkSecurityGroups/msft-vnet-prod-eu-dns-dns-inbound-nsg-westeurope"
        }
      }

      outbound_subnet = {
        address_prefixes = ["172.16.16.16/28"]
        network_security_group = {
          id = "/subscriptions/2f69b2b1-5fe0-487d-8c82-52f5edeb454e/resourceGroups/msft-connectivity-prod-eu-rg/providers/Microsoft.Network/networkSecurityGroups/msft-vnet-prod-eu-dns-dns-outbound-nsg-westeurope"
        }
      }

      outbound_endpoints = {
        default = {}
      }

      # Optional: DNS forwarding ruleset (hybrid/on-prem)
      # Disabled by default for prod EU to avoid creating new DNS forwarding resources
      # unless you explicitly want hybrid forwarding in this region.
      #
      # Note: if forwarding_rulesets is configured, keep exactly ONE outbound_endpoints entry.
      #
      # forwarding_rulesets = {
      #   default = {
      #     # DNS forwarding ruleset: ruleset-default-default
      #     name = "ruleset-default-default"
      #
      #     rules = {
      #       corp = {
      #         domain_name = "corp.contoso.com."
      #         target_dns_servers = [
      #           { ip_address = "10.0.0.10", port = 53 },
      #           { ip_address = "10.0.0.11", port = 53 },
      #         ]
      #       }
      #     }
      #   }
      # }
    }

    # Private DNS Zones for Private Endpoints
    # Uses the AVM module's built-in zone catalog (Microsoft Learn list).
    # For non-primary hubs, AVM defaults to creating only regional zones ({regionName}/{regionCode}).
    private_dns_zones = {
      auto_registration_zone_enabled = false
    }
  }
}

