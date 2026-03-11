###############################################
# Resource groups
#
# This section defines the resource groups this environment will create and
# then reference from other blocks (vWAN, vHub, firewall policy, ExpressRoute).
#
# Key = internal handle used by `resource_group_key` references.
#
# Optional vs baseline
# - Baseline in most deployments: `virtual_wan_settings` + `virtual_hubs`.
# - Optional: everything else (firewall policy/rules, ExpressRoute circuits,
#   monitoring workspaces, etc.) can be omitted or left empty to disable.
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

# Mirrors AVM input `enable_telemetry`.
enable_telemetry = false

# Module-level tags (AVM input `tags`).
# Most AVM-managed resources inherit tags from here unless a more specific
# object-level `tags` override is provided.
tags = {
  environment = "prod"
  workload    = "msft-vhub"
}

###############################################
# Network Security Groups (NSGs)
#
# Created in this stack so subnets can reference them by key.
###############################################
network_security_groups = {
  prod_sea_dns_inbound = {
    name               = "msft-vnet-prod-sea-dns-dns-inbound-nsg-southeastasia"
    resource_group_key = "prod_hub"
  }

  prod_sea_dns_outbound = {
    name               = "msft-vnet-prod-sea-dns-dns-outbound-nsg-southeastasia"
    resource_group_key = "prod_hub"
  }

  prod_eu_dns_inbound = {
    name               = "msft-vnet-prod-eu-dns-dns-inbound-nsg-westeurope"
    resource_group_key = "prod_hub_eu"
  }

  prod_eu_dns_outbound = {
    name               = "msft-vnet-prod-eu-dns-dns-outbound-nsg-westeurope"
    resource_group_key = "prod_hub_eu"
  }
}

###############################################
# RBAC (Azure Role Assignments)
#
# AVM basic usage: provide Entra object IDs + explicit scope IDs.
#
# This grants `Owner` on the prod resource groups to:
# - Group: ad58e86d-fdc0-4a37-9eee-83f7bab3a201
# - User:  dff70d67-3efe-4549-a63f-f8e1e6f3ec9d
###############################################
role_assignments_azure_resource_manager = {
  # Southeast Asia hub RG
  prod_hub_owner_group = {
    principal_id             = "ad58e86d-fdc0-4a37-9eee-83f7bab3a201"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_hub"
  }

  prod_hub_owner_user = {
    principal_id             = "dff70d67-3efe-4549-a63f-f8e1e6f3ec9d"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_hub"
  }

  # Europe hub RG
  prod_hub_eu_owner_group = {
    principal_id             = "ad58e86d-fdc0-4a37-9eee-83f7bab3a201"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_hub_eu"
  }

  prod_hub_eu_owner_user = {
    principal_id             = "dff70d67-3efe-4549-a63f-f8e1e6f3ec9d"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_hub_eu"
  }

  # Shared connectivity RG (vWAN RG)
  prod_connectivity_owner_group = {
    principal_id             = "ad58e86d-fdc0-4a37-9eee-83f7bab3a201"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_connectivity"
  }

  prod_connectivity_owner_user = {
    principal_id             = "dff70d67-3efe-4549-a63f-f8e1e6f3ec9d"
    role_definition_name     = "Owner"
    scope_resource_group_key = "prod_connectivity"
  }
}

###############################################
# Monitoring (Azure Firewall)
#
# Creates one dedicated Log Analytics Workspace per vHub firewall
# and wires Azure Firewall diagnostics (allLogs + AllMetrics) to it.
#
# Optional:
# - Omit this block (or set it to `{}`) to avoid creating firewall monitoring.
# - Map keys must match the `virtual_hubs` hub keys (e.g., `prod`, `prod_eu`).
###############################################
firewall_log_analytics_workspaces = {
  # Southeast Asia (southeastasia) - vHub key: prod
  prod = {
    name               = "msft-prod-sea-firewall-law"
    resource_group_key = "prod_hub"
    tags = {
      environment = "prod"
      workload    = "msft-firewall-law"
    }
  }

  # Europe (westeurope) - vHub key: prod_eu
  prod_eu = {
    name               = "msft-prod-eu-firewall-law"
    resource_group_key = "prod_hub_eu"
    tags = {
      environment = "prod"
      workload    = "msft-firewall-law"
    }
  }
}

###############################################
# Monitoring (ExpressRoute Gateway)
#
# Creates one dedicated Log Analytics Workspace per vHub ExpressRoute gateway
# and wires ExpressRoute gateway diagnostics (AllMetrics) to it.
#
# Optional:
# - Omit this block (or set it to `{}`) to avoid creating ExpressRoute gateway monitoring.
# - Map keys must match the `virtual_hubs` hub keys (e.g., `prod`, `prod_eu`).
#
# Note: ExpressRoute Gateway diagnostic categories can vary by resource type.
# For vWAN ExpressRoute Gateways, Azure currently exposes `AllMetrics` and may
# not expose log categories.
###############################################
expressroute_gateway_log_analytics_workspaces = {
  # Southeast Asia (southeastasia) - vHub key: prod
  prod = {
    name               = "msft-prod-sea-ergw-law"
    resource_group_key = "prod_hub"
    tags = {
      environment = "prod"
      workload    = "msft-ergw-law"
    }
  }

  # Europe (westeurope) - vHub key: prod_eu
  prod_eu = {
    name               = "msft-prod-eu-ergw-law"
    resource_group_key = "prod_hub_eu"
    tags = {
      environment = "prod"
      workload    = "msft-ergw-law"
    }
  }
}

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
virtual_wan_settings = {
  enabled_resources = {
    ddos_protection_plan = false
  }

  virtual_wan = {
    name                = "msft-prod-sea-vwan"
    resource_group_name = "msft-prod-connectivity-rg"
    location            = "southeastasia"
    type                = "Standard"

    allow_branch_to_branch_traffic = true
    disable_vpn_encryption         = false

    tags = {
      environment = "prod"
      workload    = "msft-vwan"
    }
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

        application_rule_collection = [
          {
            action   = "Allow"
            name     = "aks-app"
            priority = 200
            rule = [
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
        ]

        network_rule_collection = [
          {
            action   = "Allow"
            name     = "aks-network"
            priority = 210
            rule = [
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
              }
            ]
          }
        ]
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

        application_rule_collection = [
          {
            action   = "Allow"
            name     = "aks-app"
            priority = 200
            rule = [
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
              }
            ]
          }
        ]

        network_rule_collection = [
          {
            action   = "Allow"
            name     = "aks-network"
            priority = 210
            rule = [
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
              }
            ]
          }
        ]
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
    location                          = "southeastasia"
    default_parent_resource_group_key = "prod_hub"

    enabled_resources = {
      firewall                              = true
      firewall_policy                       = false
      bastion                               = false
      virtual_network_gateway_express_route = true
      virtual_network_gateway_vpn           = true
      private_dns_zones                     = true
      private_dns_resolver                  = true
      sidecar_virtual_network               = true
    }

    hub = {
      name           = "msft-vhub-prod-sea"
      address_prefix = "10.2.0.0/20"

      # Optional AVM hub settings (explicit here so they are TFVARS-configurable).
      hub_routing_preference                 = "ExpressRoute"
      virtual_router_auto_scale_min_capacity = 2
      tags = {
        environment = "prod"
        workload    = "msft-vhub"
      }
    }

    firewall = {
      name                = "msft-vhub-prod-sea-firewall"
      sku_name            = "AZFW_Hub"
      sku_tier            = "Standard"
      firewall_policy_key = "prod"
      zones               = []
    }

    virtual_network_gateways = {
      express_route = {
        name        = "msft-vhub-prod-sea-ergw"
        scale_units = 1
      }

      vpn = {
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

    sidecar_virtual_network = {
      name          = "msft-vnet-prod-sea-dns"
      address_space = ["10.2.16.0/24"]

      virtual_network_connection_settings = {
        name                      = "msft-vnet-prod-sea-dns-to-vhub"
        internet_security_enabled = false
      }

      subnets = {
        dns_resolver = {
          name             = "dns-inbound"
          address_prefixes = ["10.2.16.0/28"]
          network_security_group = {
            key = "prod_sea_dns_inbound"
          }
          delegations = [
            {
              name = "dnsResolvers"
              service_delegation = {
                name = "Microsoft.Network/dnsResolvers"
              }
            }
          ]
        }

        outbound = {
          name             = "dns-outbound"
          address_prefixes = ["10.2.16.16/28"]
          network_security_group = {
            key = "prod_sea_dns_outbound"
          }
          delegations = [
            {
              name = "dnsResolvers"
              service_delegation = {
                name = "Microsoft.Network/dnsResolvers"
              }
            }
          ]
        }
      }
    }

    private_dns_resolver = {
      name                             = "msft-pdr-prod-sea"
      default_inbound_endpoint_enabled = false

      inbound_endpoints = {
        default = {
          subnet_name                  = "dns-inbound"
          private_ip_allocation_method = "Dynamic"
          merge_with_module_tags       = true
        }
      }

      outbound_endpoints = {
        default = {
          subnet_name            = "dns-outbound"
          merge_with_module_tags = true

          forwarding_ruleset = {
            default = {
              name                                        = "ruleset-default-default"
              link_with_outbound_endpoint_virtual_network = true

              rules = {
                corp = {
                  domain_name = "corp.contoso.com."
                  destination_ip_addresses = {
                    "10.0.0.10" = "53"
                    "10.0.0.11" = "53"
                  }
                }
              }
            }
          }
        }
      }
    }

    private_dns_zones = {
      tags = {
        environment = "prod"
        workload    = "msft-vwan"
      }
      auto_registration_zone_enabled = false
      private_link_private_dns_zones_regex_filter = {
        enabled = false
      }
    }
  }

  ###############################################
  # Europe (westeurope)
  ###############################################
  prod_eu = {
    location                          = "westeurope"
    default_parent_resource_group_key = "prod_hub_eu"

    enabled_resources = {
      firewall                              = true
      firewall_policy                       = false
      bastion                               = false
      virtual_network_gateway_express_route = true
      virtual_network_gateway_vpn           = false
      private_dns_zones                     = true
      private_dns_resolver                  = true
      sidecar_virtual_network               = true
    }

    hub = {
      name           = "msft-vhub-prod-eu"
      address_prefix = "172.16.0.0/20"

      # Optional AVM hub settings (explicit here so they are TFVARS-configurable).
      hub_routing_preference                 = "ExpressRoute"
      virtual_router_auto_scale_min_capacity = 2
      tags = {
        environment = "prod"
        workload    = "msft-vhub"
      }
    }

    firewall = {
      name                = "msft-vhub-prod-eu-firewall"
      sku_name            = "AZFW_Hub"
      sku_tier            = "Standard"
      firewall_policy_key = "prod_eu"
      zones               = []
    }

    virtual_network_gateways = {
      express_route = {
        name        = "msft-vhub-prod-eu-ergw"
        scale_units = 1
      }
    }

    sidecar_virtual_network = {
      name          = "msft-vnet-prod-eu-dns"
      address_space = ["172.16.16.0/24"]

      virtual_network_connection_settings = {
        name                      = "msft-vnet-prod-eu-dns-to-vhub"
        internet_security_enabled = false
      }

      subnets = {
        dns_resolver = {
          name             = "dns-inbound"
          address_prefixes = ["172.16.16.0/28"]
          network_security_group = {
            key = "prod_eu_dns_inbound"
          }
          delegations = [
            {
              name = "dnsResolvers"
              service_delegation = {
                name = "Microsoft.Network/dnsResolvers"
              }
            }
          ]
        }

        outbound = {
          name             = "dns-outbound"
          address_prefixes = ["172.16.16.16/28"]
          network_security_group = {
            key = "prod_eu_dns_outbound"
          }
          delegations = [
            {
              name = "dnsResolvers"
              service_delegation = {
                name = "Microsoft.Network/dnsResolvers"
              }
            }
          ]
        }
      }
    }

    private_dns_resolver = {
      name                             = "msft-pdr-prod-eu"
      default_inbound_endpoint_enabled = false

      inbound_endpoints = {
        default = {
          subnet_name                  = "dns-inbound"
          private_ip_allocation_method = "Dynamic"
          merge_with_module_tags       = true
        }
      }

      outbound_endpoints = {
        default = {
          subnet_name            = "dns-outbound"
          merge_with_module_tags = true
        }
      }
    }

    private_dns_zones = {
      tags = {
        environment = "prod"
        workload    = "msft-vwan"
      }
      auto_registration_zone_enabled = false
      private_link_private_dns_zones_regex_filter = {
        enabled      = true
        regex_filter = "{regionName}|{regionCode}"
      }
    }
  }
}

