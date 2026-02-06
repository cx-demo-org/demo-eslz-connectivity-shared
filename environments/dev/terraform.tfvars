existing_resource_groups = {
  dev_hub = {
    name = "msft-vhub-dev-rg"
  }
}

# Target subscription/tenant for hub resources (vHub, Azure Firewall, Firewall Policy, etc.)
hub_subscription_id = "4a1d92dd-e86a-4061-bd18-5b625d9d0c52"
hub_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

# vWAN subscription/tenant. Keep explicit to avoid accidental defaults.
virtual_wan_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
virtual_wan_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

# vWAN is created once (typically in prod) and referenced from dev.
existing_virtual_wan = {
  name                = "msft-prod-sea-vwan"
  resource_group_name = "msft-prod-connectivity-rg"
}

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
  }
}
