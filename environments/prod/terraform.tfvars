###############################################
# Resource groups
#
# This section defines the resource groups this environment will create and
# then reference from other blocks (vWAN, vHub, firewall policy, ExpressRoute).
#
# Key = internal handle used by `resource_group_key` references.
###############################################
resource_groups = {
  prod_connectivity = {
    name     = "demo-prod-connectivity-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "demo-vwan"
    }
  }

  prod_hub = {
    name     = "demo-vhub-prod-rg"
    location = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "demo-vhub"
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
hub_subscription_id = "ADD_YOUR_HUB_SUBSCRIPTION_ID"
hub_tenant_id       = "ADD_YOUR_TENANT_ID"

# vWAN subscription/tenant (prod owns/creates the vWAN in this state).
virtual_wan_subscription_id = "ADD_YOUR_VWAN_SUBSCRIPTION_ID"
virtual_wan_tenant_id       = "ADD_YOUR_TENANT_ID"

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
  name               = "demo-prod-sea-vwan"
  resource_group_key = "prod_connectivity"
  location           = "southeastasia"
  sku                = "Standard"

  enable_module_telemetry = false

  allow_branch_to_branch_traffic = true
  disable_vpn_encryption         = false

  tags = {
    environment = "prod"
    workload    = "demo-vwan"
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
expressroute_circuits = {
  prod_primary = {
    name               = "demo-prod-sea-er-circuit-01"
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
      workload    = "demo-expressroute"
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
  prod = {
    name               = "demo-vhub-prod-firewall-policy"
    resource_group_key = "prod_hub"
    location           = "southeastasia"
    tags = {
      environment = "prod"
      workload    = "demo-fwpolicy"
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
}

###############################################
# Virtual hubs (vHubs)
#
# Defines the vHub(s) for this environment and optionally attaches:
# - Azure Firewall (Hub SKU)
# - ExpressRoute gateway (Virtual WAN gateway inside the vHub)
###############################################
virtual_hubs = {
  prod = {
    name               = "demo-vhub-prod"
    resource_group_key = "prod_hub"
    location           = "southeastasia"
    address_prefix     = "10.2.0.0/20"

    tags = {
      environment = "prod"
      workload    = "demo-vhub"
    }

    firewall = {
      name                = "demo-vhub-prod-firewall"
      firewall_policy_key = "prod"
    }

    expressroute_gateway = {
      name        = "demo-vhub-prod-ergw"
      scale_units = 1
    }

    # Optional: Private DNS Resolver (creates sidecar VNet + vHub connection + resolver)
    private_dns_resolver = {
      # resource_group_key = "prod_dns"  # optional: separate RG key for DNS resources
      name = "demo-pdr-prod"

      sidecar_virtual_network = {
        name          = "demo-vnet-prod-dns"
        address_space = ["10.2.16.0/24"]
      }

      inbound_subnet = {
        address_prefixes = ["10.2.16.0/28"]
      }

      outbound_subnet = {
        address_prefixes = ["10.2.16.16/28"]
      }

      outbound_endpoints = {
        default = {}
      }

      # DNS forwarding ruleset (hybrid/on-prem placeholder)
      # Note: if forwarding_rulesets is configured, keep exactly ONE outbound_endpoints entry.
      forwarding_rulesets = {
        default = {
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
  }
}

