existing_resource_groups = {
  prod_connectivity = {
    name = "msft-prod-connectivity-rg"
  }

  prod_hub = {
    name = "msft-vhub-prod-rg"
  }
}

# Target subscription/tenant for hub resources (vHub, Azure Firewall, Firewall Policy, etc.)
hub_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
hub_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

# vWAN subscription/tenant (prod owns/creates the vWAN in this state).
virtual_wan_subscription_id = "2f69b2b1-5fe0-487d-8c82-52f5edeb454e"
virtual_wan_tenant_id       = "9a9712e7-1382-4528-8495-b52ae7688acb"

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

firewall_policies = {
  prod = {
    name               = "msft-vhub-prod-firewall-policy"
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

virtual_hubs = {
  prod = {
    name               = "msft-vhub-prod"
    resource_group_key = "prod_hub"
    location           = "southeastasia"
    address_prefix     = "10.2.0.0/20"

    tags = {
      environment = "prod"
      workload    = "msft-vhub"
    }

    firewall = {
      name                = "msft-vhub-prod-firewall"
      firewall_policy_key = "prod"
    }
  }
}
