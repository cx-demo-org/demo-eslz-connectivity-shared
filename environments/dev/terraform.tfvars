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
    name     = "demo-vhub-dev-rg"
    location = "southeastasia"
    tags = {
      environment = "dev"
      workload    = "demo-vhub"
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
hub_subscription_id = "ADD_YOUR_HUB_SUBSCRIPTION_ID"
hub_tenant_id       = "ADD_YOUR_TENANT_ID"

# vWAN subscription/tenant. Keep explicit to avoid accidental defaults.
virtual_wan_subscription_id = "ADD_YOUR_VWAN_SUBSCRIPTION_ID"
virtual_wan_tenant_id       = "ADD_YOUR_TENANT_ID"

###############################################
# Virtual WAN (vWAN)
#
# Dev does not create the vWAN; it references the shared vWAN created in prod.
###############################################
# vWAN is created once (typically in prod) and referenced from dev.
existing_virtual_wan = {
  name                = "demo-prod-sea-vwan"
  resource_group_name = "demo-prod-connectivity-rg"
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
    name               = "demo-dev-sea-er-circuit-01"
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
  dev = {
    name               = "demo-vhub-dev-firewall-policy"
    resource_group_key = "dev_hub"
    location           = "southeastasia"
    tags = {
      environment = "dev"
      workload    = "demo-fwpolicy"
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
    name               = "demo-vhub-dev"
    resource_group_key = "dev_hub"
    location           = "southeastasia"
    address_prefix     = "192.168.0.0/20"

    tags = {
      environment = "dev"
      workload    = "demo-vhub"
    }

    firewall = {
      name                = "demo-vhub-dev-firewall"
      firewall_policy_key = "dev"
    }

    expressroute_gateway = {
      name        = "demo-vhub-dev-ergw"
      scale_units = 1
    }
  }
}
