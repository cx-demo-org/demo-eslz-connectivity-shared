# ──────────────────────────────────────────────────────────────
# ALZ Spoke Networking & Shared Services – Variable Definitions
# ──────────────────────────────────────────────────────────────
# This file documents every input variable with its type, shape,
# defaults, and security implications.  Uncomment and fill in
# the sections you need.
# ──────────────────────────────────────────────────────────────

# ─── Global ──────────────────────────────────────────────────

# (Required) Azure region for all resources.
# Changing this forces recreation of all resources.
location = "australiaeast"

# (Optional) Common tags applied to every taggable resource.
# Per-resource tags are merged on top. Default: {}
tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
}

# (Optional) Resource lock applied to all AVM root-module resources.
# Set to null to disable.  kind: "CanNotDelete" | "ReadOnly"
# lock = {
#   kind = "CanNotDelete"
#   name = "spoke-lock"
# }

# ─── Resource Groups ────────────────────────────────────────

# (Required) At least one resource group is needed.
# Map key is a reference key used by other variables (resource_group_key).
resource_groups = {
  rg_networking = {
    name = "rg-spoke-networking"
    # location = "australiaeast"   # defaults to var.location
    # tags     = {}                # merged with var.tags
  }
}

# ─── Log Analytics Workspace ────────────────────────────────

# (Optional) Resource ID of an existing Log Analytics workspace.
# When null, the pattern auto-creates one using the configuration below.
# Default: null
# log_analytics_workspace_id = "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/..."

# (Required when log_analytics_workspace_id is null)
# Configuration for the auto-created workspace.
log_analytics_workspace_configuration = {
  name               = "law-shared-services"
  resource_group_key = "rg_networking"
  # location         = "australiaeast"        # defaults to var.location
  # sku              = "PerGB2018"            # default
  # retention_in_days = 30                    # default
  # tags             = {}
}

# ─── Network Security Groups ────────────────────────────────

# (Optional) Map of NSGs.  security_rules = {} means only Azure default rules.
# Default: {}
# network_security_groups = {
#   nsg_app = {
#     name               = "nsg-app-subnet"
#     resource_group_key = "rg_networking"
#     # location         = "australiaeast"
#     security_rules = {
#       allow_https = {
#         name                       = "AllowHTTPS"
#         priority                   = 100
#         direction                  = "Inbound"
#         access                     = "Allow"
#         protocol                   = "Tcp"
#         destination_port_range     = "443"
#         source_address_prefix      = "*"
#         destination_address_prefix = "*"
#         source_port_range          = "*"
#       }
#     }
#     # tags = {}
#     # diagnostic_settings = {
#     #   to_law = {
#     #     name = "diag-nsg-to-law"
#     #     # storage_account = {
#     #     #   key = "sa_diag"    # OR resource_id = "/subscriptions/.../storageAccounts/..."
#     #     # }
#     #   }
#     # }
#   }
# }

# ─── Route Tables ────────────────────────────────────────────

# (Optional) Map of route tables.  Associate to subnets via route_table_key.
# Default: {}
# route_tables = {
#   rt_default = {
#     name               = "rt-default"
#     resource_group_key = "rg_networking"
#     # bgp_route_propagation_enabled = true
#     routes = {
#       to_firewall = {
#         name                   = "to-hub-firewall"
#         address_prefix         = "0.0.0.0/0"
#         next_hop_type          = "VirtualAppliance"
#         next_hop_in_ip_address = "10.0.0.4"
#       }
#     }
#     # tags = {}
#   }
# }

# ─── Virtual Networks ───────────────────────────────────────

# (Optional) Map of spoke VNets with subnets, peering, NSG/RT associations.
# Default: {}
# virtual_networks = {
#   vnet_spoke = {
#     name               = "vnet-spoke-shared"
#     address_space      = ["10.1.0.0/16"]
#     resource_group_key = "rg_networking"
#     # location         = "australiaeast"
#     # dns_servers      = ["10.0.0.5"]
#
#     subnets = {
#       snet_app = {
#         name           = "snet-app"
#         address_prefix = "10.1.1.0/24"    # XOR address_prefixes — exactly one
#         # address_prefixes           = ["10.1.1.0/24"]
#         # network_security_group_key = "nsg_app"
#         # route_table_key            = "rt_default"
#         # default_outbound_access_enabled   = false   # default
#         # private_endpoint_network_policies = "Enabled"
#       }
#     }
#
#     # peerings = {
#     #   to_hub = {
#     #     name                               = "spoke-to-hub"
#     #     remote_virtual_network_resource_id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/vnet-hub"
#     #     allow_forwarded_traffic            = true
#     #     use_remote_gateways                = false
#     #   }
#     # }
#     # tags = {}
#     # diagnostic_settings = {
#     #   to_law = {
#     #     name = "diag-vnet-to-law"
#     #   }
#     # }
#   }
# }

# ─── Private DNS Zone Links (BYO) ───────────────────────────

# (Optional) Link existing Private DNS Zones to spoke VNets.
# Default: {}
# byo_private_dns_zone_links = {
#   link_blob = {
#     name                = "link-blob-to-spoke"
#     private_dns_zone_id = "/subscriptions/.../providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
#     virtual_network_key = "vnet_spoke"     # must exist in virtual_networks
#     # registration_enabled = false
#     # resolution_policy    = "Default"
#     # tags = {}
#   }
# }

# ─── Managed Identities ─────────────────────────────────────

# (Optional) User-assigned managed identities.
# Default: {}
# managed_identities = {
#   mi_app = {
#     name               = "mi-shared-services"
#     resource_group_key = "rg_networking"
#     # location = "australiaeast"
#     # tags     = {}
#   }
# }

# ─── Key Vaults ──────────────────────────────────────────────

# (Optional) Map of Key Vaults with RBAC role assignments and private endpoints.
# public_network_access_enabled defaults to false (secure-by-default).
# Default: {}
# key_vaults = {
#   kv_shared = {
#     name               = "kv-shared-svc"
#     resource_group_key = "rg_networking"
#     # sku_name                      = "premium"    # default
#     # public_network_access_enabled = false         # default
#     # purge_protection_enabled      = true          # default
#
#     # role_assignments = {
#     #   kv_reader = {
#     #     role_definition_id_or_name = "Key Vault Secrets User"
#     #     managed_identity_key       = "mi_app"    # XOR principal_id
#     #     # principal_id             = "00000000-0000-0000-0000-000000000000"
#     #   }
#     # }
#
#     # private_endpoints = {
#     #   pe_kv = {
#     #     subnet_resource_id            = "/subscriptions/.../subnets/snet-pe"
#     #     private_dns_zone_resource_ids = ["/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"]
#     #   }
#     # }
#     # tags = {}
#     # diagnostic_settings = {
#     #   to_law = {
#     #     name = "diag-kv-to-law"
#     #   }
#     # }
#   }
# }

# ─── Standalone Role Assignments ─────────────────────────────

# (Optional) Role assignments at arbitrary scopes (not
# scoped to an AVM-managed resource).
# Default: {}
# role_assignments = {
#   ra_reader = {
#     role_definition_id_or_name = "Reader"
#     scope                      = "/subscriptions/..."
#     managed_identity_key       = "mi_app"  # XOR principal_id
#     # principal_id             = "00000000-0000-0000-0000-000000000000"
#   }
# }

# ─── vWAN Hub Connections ────────────────────────────────────

# (Optional) Connect spoke VNets to vWAN hubs.
# Default: {}
# vhub_connectivity_definitions = {
#   conn_spoke = {
#     vhub_resource_id = "/subscriptions/.../providers/Microsoft.Network/virtualHubs/vhub-prod"
#     virtual_network = {
#       key = "vnet_spoke"   # XOR id — one must be set
#       # id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/..."
#     }
#     # internet_security_enabled = true   # default (routes through hub firewall)
#     # routing = {
#     #   associated_route_table_id = "/subscriptions/.../providers/Microsoft.Network/virtualHubs/vhub-prod/hubRouteTables/defaultRouteTable"
#     #   propagated_route_table = {
#     #     route_table_ids = ["/subscriptions/.../providers/Microsoft.Network/virtualHubs/vhub-prod/hubRouteTables/defaultRouteTable"]
#     #     labels          = ["default"]
#     #   }
#     #   static_vnet_route = {
#     #     name                = "to-onprem"
#     #     address_prefixes    = ["10.0.0.0/8"]
#     #     next_hop_ip_address = "10.1.0.4"
#     #   }
#     # }
#   }
# }

# ─── Bastion Hosts ────────────────────────────────────────────

# (Optional) Map of Azure Bastion Host configurations.
# Empty map = no Bastion hosts deployed.
# For non-Developer SKUs, ip_configuration is required with an
# AzureBastionSubnet (minimum /26).  For Developer SKU, set
# virtual_network instead.
# Default: {}
# bastion_hosts = {
#   bastion_shared = {
#     name               = "bastion-shared"
#     resource_group_key = "rg_networking"
#     # sku              = "Standard"             # default
#     # zones            = ["1", "2", "3"]        # default (zone-redundant)
#
#     ip_configuration = {
#       network_configuration = {
#         subnet_resource_id = "/subscriptions/.../subnets/AzureBastionSubnet"
#       }
#       # create_public_ip = true                 # default
#     }
#
#     # copy_paste_enabled        = true          # default
#     # file_copy_enabled         = false         # default
#     # ip_connect_enabled        = false         # default
#     # tunneling_enabled         = false         # default
#     # private_only_enabled      = false         # default
#     # scale_units               = 2             # default
#     # tags = {}
#     # diagnostic_settings = {
#     #   to_law = {
#     #     name = "diag-bastion-to-law"
#     #   }
#     # }
#   }
# }

# ─── Network Watcher / Flow Logs ────────────────────────────

# (Optional) Network Watcher VNet flow logs.  null = no flow logs.
# References an existing Network Watcher (typically auto-created by Azure).
# Default: null
# flowlog_configuration = {
#   network_watcher_id   = "/subscriptions/.../providers/Microsoft.Network/networkWatchers/NetworkWatcher_australiaeast"
#   network_watcher_name = "NetworkWatcher_australiaeast"
#   resource_group_name  = "NetworkWatcherRG"
#   # location           = "australiaeast"     # defaults to var.location
#
#   flow_logs = {
#     vnet_flow = {
#       enabled            = true
#       name               = "fl-spoke-vnet"
#       target_resource_id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/vnet-spoke-shared"
#       storage_account_id = "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/stflowlogs"
#       retention_policy = {
#         enabled = true
#         days    = 90
#       }
#       # traffic_analytics = {
#       #   enabled               = true
#       #   interval_in_minutes   = 10
#       #   workspace_id          = "guid"
#       #   workspace_region      = "australiaeast"
#       #   workspace_resource_id = "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/..."
#       # }
#       # version = 2
#     }
#   }
#   # tags = {}
# }