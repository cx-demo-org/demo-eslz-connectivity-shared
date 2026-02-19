###############################################
# Resource groups
#
# This section defines the resource groups this environment will create and
# then reference from other blocks (vHub, firewall policy, ExpressRoute).
#
# Key = internal handle used by `resource_group_key` references.
###############################################
resource_groups = {
  dev_hub = {
    name     = "msft-vhub-dev-rg"
    location = "southeastasia"
    tags = {
      environment = "dev"
      workload    = "msft-vhub"
    }
  }
}

###############################################
# Subscription / tenant targeting
#
# These IDs control where resources are created/looked up.
# - Hub subscription: vHub, Azure Firewall, Firewall Policy, ExpressRoute.
# - vWAN subscription: vWAN lookup (dev references the prod-owned vWAN).
###############################################
# Target subscription/tenant for hub resources (vHub, Azure Firewall, Firewall Policy, etc.)
hub_subscription_id = "4a1d92dd-e86a-4061-bd18-5b625d9d0c52"
hub_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

# vWAN subscription/tenant. Keep explicit to avoid accidental defaults.
virtual_wan_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
virtual_wan_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

###############################################
# Virtual WAN (vWAN)
#
# Dev does not create the vWAN; it references the shared vWAN created in prod.
###############################################
# vWAN is created once (typically in prod) and referenced from dev.
existing_virtual_wan = {
  name                = "msft-prod-sea-vwan"
  resource_group_name = "msft-prod-connectivity-rg"
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
# If you want dev to also create circuits, define them here.
expressroute_circuits = {
  dev_primary = {
    name               = "msft-dev-sea-er-circuit-01"
    resource_group_key = "dev_hub"
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
      environment = "dev"
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
  dev = {
    name               = "msft-vhub-dev-firewall-policy"
    resource_group_key = "dev_hub"
    location           = "southeastasia"
    tags = {
      environment = "dev"
      workload    = "msft-fwpolicy"
    }

    # Rules are explicitly managed via tfvars so end users can customize them.
    rule_collection_groups = {
      # Existing policy also has an empty placeholder rule collection group named "baseline".
      # Keep it managed to avoid import-time drift.
      baseline = {
        priority                     = 500
        application_rule_collections = {}
        network_rule_collections     = {}
      }

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
                protocols        = [{ type = "Https", port = 443 }]
                destination_fqdns = [
                  "mcr.microsoft.com",
                  "*.data.mcr.microsoft.com",
                  "*.blob.core.windows.net",
                  "management.azure.com",
                  "login.microsoftonline.com",
                  "graph.microsoft.com",
                  "*.ods.opinsights.azure.com",
                  "*.oms.opinsights.azure.com",
                  "*.monitoring.azure.com",
                  "*.securitycenter.windows.com",
                ]
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
                name                  = "ntp"
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
  dev = {
    name               = "msft-vhub-dev"
    resource_group_key = "dev_hub"
    location           = "southeastasia"
    address_prefix     = "192.168.0.0/20"

    tags = {
      environment = "dev"
      workload    = "msft-vhub"
    }

    firewall = {
      name                = "msft-vhub-dev-firewall"
      firewall_policy_key = "dev"
    }

    expressroute_gateway = {
      name        = "msft-vhub-dev-ergw"
      scale_units = 1
    }

    # Optional: Private DNS Resolver (creates sidecar VNet + vHub connection + resolver)
    # private_dns_resolver = {
    #   # resource_group_key = "dev_dns"  # optional: separate RG key for DNS resources
    #   name = "msft-pdr-dev"
    #
    #   sidecar_virtual_network = {
    #     name          = "msft-vnet-dev-dns"
    #     address_space = ["192.168.16.0/24"]
    #   }
    #
    #   inbound_subnet = {
    #     address_prefixes = ["192.168.16.0/28"]
    #   }
    #
    #   outbound_subnet = {
    #     address_prefixes = ["192.168.16.16/28"]
    #   }
    #
    #   outbound_endpoints = {
    #     default = {}
    #   }
    #
    #   forwarding_rulesets = {
    #     default = {
    #       rules = {
    #         corp = {
    #           domain_name = "corp.contoso.com."
    #           target_dns_servers = [
    #             { ip_address = "10.0.0.10" },
    #             { ip_address = "10.0.0.11" },
    #           ]
    #         }
    #       }
    #     }
    #   }
    # }
  }
}
