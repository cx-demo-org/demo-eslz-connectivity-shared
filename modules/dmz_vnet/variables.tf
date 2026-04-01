variable "location" {
  type        = string
  description = <<-EOT
    The Azure region for all resources. Changing this forces recreation of all resources.

    All AVM module calls default their location to this value when not overridden per-resource.
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Common tags applied to all resources that support tagging. Per-resource tags are merged on top
    of these.

    Note: vHub connections (azurerm_virtual_hub_connection) do not support tags; this variable is
    not passed to the vWAN connection submodule.
  EOT
}



variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<-EOT
    Resource lock applied to AVM root-module resources that expose the lock interface (resource
    group, VNet, NSG, route table, Key Vault, Bastion, Log Analytics workspace, managed identity).

    Does not apply to AVM submodule resources (DNS zone VNet links, vHub connections) as those
    submodules do not implement the lock interface. Per-resource-group lock overrides are available
    via the resource_groups variable's lock field.

    Set to null to disable. Possible kind values: 'CanNotDelete', 'ReadOnly'.
  EOT

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], try(var.lock.kind, ""))
    error_message = "lock.kind must be 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "resource_groups" {
  type = map(object({
    name     = string
    location = optional(string)
    tags     = optional(map(string), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
  }))
  description = <<-EOT
    Map of resource groups to create. The map key is used as a reference key for other resources.

    Uses: Azure/avm-res-resources-resourcegroup/azurerm v0.2.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm

    - name:             Resource group name.
    - location:         Azure region. Defaults to var.location if not specified.
    - tags:             Per-resource-group tags, merged with var.tags.
    - lock:             Per-resource-group lock override. When set, overrides var.lock for this RG.
                        See AVM module variable: lock.
    - role_assignments: Per-resource-group RBAC assignments.
                        See AVM module variable: role_assignments.
  EOT
}

variable "byo_log_analytics_workspace" {
  type = object({
    resource_id = string
    location    = string
  })
  default     = null
  description = <<-EOT
    Bring-your-own Log Analytics workspace. Provide the resource ID and location of an
    existing workspace. If null, the pattern auto-creates one using
    log_analytics_workspace_configuration.
  EOT
}

variable "log_analytics_workspace_configuration" {
  type = object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "PerGB2018")
    retention_in_days  = optional(number, 30)
    tags               = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    private_endpoints = optional(map(object({
      name = optional(string, null)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      private_dns_zone = optional(object({
        resource_ids = optional(set(string))
        keys         = optional(set(string))
      }))
      tags = optional(map(string), null)
    })), {})
  })
  default     = null
  description = <<-EOT
    Configuration for the auto-created Log Analytics workspace. Used only when
    byo_log_analytics_workspace is null.

    Uses: Azure/avm-res-operationalinsights-workspace/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm

    - name:               Workspace name (required).
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - sku:                Pricing tier. Default: "PerGB2018".
    - retention_in_days:  Data retention. Default: 30.
    - tags:               Per-workspace tags, merged with var.tags.
    - role_assignments:   Per-workspace RBAC assignments.
                          See AVM module variable: role_assignments.
    - private_endpoints:  Private endpoint configurations for the workspace.
                          See AVM module variable: private_endpoints.
  EOT
}

variable "network_security_groups" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    security_rules = optional(map(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(set(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(set(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(set(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(set(string))
      source_application_security_group_ids      = optional(set(string))
      destination_application_security_group_ids = optional(set(string))
      description                                = optional(string)
    })), {})
    tags = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of Network Security Groups. The map key is used as a reference key for subnet associations.

    Uses: Azure/avm-res-network-networksecuritygroup/azurerm v0.5.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networksecuritygroup/azurerm

    - name:               NSG name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - security_rules:     Map of user-defined security rules. An empty map means only Azure
                          built-in default rules apply. No rules are auto-injected.
    - tags:               Per-NSG tags, merged with var.tags.
    - role_assignments:   Per-NSG RBAC assignments.
                          See AVM module variable: role_assignments.
    - diagnostic_settings: Per-NSG diagnostic settings. Each entry can send logs/metrics to a
                          Log Analytics workspace, storage account, Event Hub, or partner solution.
                          workspace_resource_id defaults to the pattern's Log Analytics workspace
                          (BYO or auto-created) but can be overridden per entry.
  EOT
}

variable "route_tables" {
  type = map(object({
    name                          = string
    resource_group_key            = string
    location                      = optional(string)
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    Map of route tables. Each can contain multiple routes. Associate to subnets via the subnet's
    route_table_key.

    Uses: Azure/avm-res-network-routetable/azurerm v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-routetable/azurerm

    - name:                          Route table name.
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - bgp_route_propagation_enabled: Enable BGP route propagation. Default: true.
    - routes:                        Map of routes with address_prefix and next_hop_type.
    - tags:                          Per-route-table tags, merged with var.tags.
  EOT
}

variable "virtual_networks" {
  type = map(object({
    name               = string
    address_space      = set(string)
    resource_group_key = string
    location           = optional(string)
    dns_servers        = optional(list(string))
    ddos_protection_plan = optional(object({
      resource_id = string
      enable      = bool
    }))
    encryption = optional(object({
      enabled     = bool
      enforcement = string
    }))
    tags = optional(map(string), {})
    peerings = optional(map(object({
      name                               = string
      remote_virtual_network_resource_id = string
      allow_forwarded_traffic            = optional(bool, true)
      allow_gateway_transit              = optional(bool, false)
      use_remote_gateways                = optional(bool, false)
      allow_virtual_network_access       = optional(bool, true)
      create_reverse_peering             = optional(bool, false)
      reverse_allow_forwarded_traffic    = optional(bool, true)
      reverse_allow_gateway_transit      = optional(bool, false)
    })), {})
    subnets = optional(map(object({
      name                       = string
      address_prefix             = optional(string)
      address_prefixes           = optional(list(string))
      network_security_group_key = optional(string)
      route_table_key            = optional(string)
      service_endpoints_with_location = optional(list(object({
        service   = string
        locations = optional(list(string), ["*"])
      })), [])
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name = string
        })
      })), [])
      default_outbound_access_enabled   = optional(bool, false)
      private_endpoint_network_policies = optional(string, "Enabled")
      role_assignments = optional(map(object({
        role_definition_id_or_name             = string
        principal_id                           = string
        description                            = optional(string, null)
        skip_service_principal_aad_check       = optional(bool, false)
        condition                              = optional(string, null)
        condition_version                      = optional(string, null)
        delegated_managed_identity_resource_id = optional(string, null)
        principal_type                         = optional(string, null)
      })), {})
    })), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of spoke virtual networks. Each entry creates a VNet with optional subnets and optional hub
    peerings via the AVM VNet module's peerings interface.

    Uses: Azure/avm-res-network-virtualnetwork/azurerm v0.17.1
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm

    - name:               VNet name.
    - address_space:      Set of CIDR ranges for the virtual network.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - dns_servers:        Custom DNS servers. Null uses Azure-provided DNS.
    - ddos_protection_plan: DDoS Protection Plan configuration.
    - encryption:         VNet encryption settings.
    - tags:               Per-VNet tags, merged with var.tags.
    - peerings:           Map of VNet peerings. Empty map = no peering (implicit toggle).
    - subnets:            Map of subnets. Each can reference NSG and route table by key.
                          Subnets support their own role_assignments.
    - role_assignments:   VNet-level RBAC assignments.
                          See AVM module variable: role_assignments.
    - diagnostic_settings: Per-VNet diagnostic settings. Each entry can send logs/metrics to a
                          Log Analytics workspace, storage account, Event Hub, or partner solution.
                          workspace_resource_id defaults to the pattern's Log Analytics workspace
                          (BYO or auto-created) but can be overridden per entry.
  EOT

  validation {
    condition = alltrue([
      for vk, vnet in var.virtual_networks : alltrue([
        for sk, subnet in vnet.subnets : (subnet.address_prefix != null) != (subnet.address_prefixes != null)
      ])
    ])
    error_message = "Each subnet must define exactly one of address_prefix or address_prefixes, not both."
  }
}

variable "private_dns_zones" {
  type = map(object({
    domain_name        = string
    resource_group_key = string
    virtual_network_links = optional(map(object({
      name                 = string
      virtual_network_key  = string
      registration_enabled = optional(bool, false)
      resolution_policy    = optional(string, "Default")
      tags                 = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    Map of Private DNS Zones to create and optionally link to VNets created by this pattern.

    Uses: Azure/avm-res-network-privatednszone/azurerm v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm

    - domain_name:          Domain name for the Private DNS Zone (e.g. "privatelink.blob.core.windows.net").
    - resource_group_key:   Key in resource_groups map for placement.
    - virtual_network_links: Map of VNet links. Each references a VNet by key from virtual_networks map.
      - name:                 Link name.
      - virtual_network_key:  Key in virtual_networks map identifying the VNet to link.
      - registration_enabled: Enable auto-registration of VM DNS records. Default: false.
      - resolution_policy:    Resolution policy. Default: "Default".
      - tags:                 Per-link tags, merged with var.tags.
    - tags:                 Per-zone tags, merged with var.tags.

    For linking to existing (BYO) Private DNS Zones not managed by this pattern, use
    byo_private_dns_zone_links instead.
  EOT
}

variable "byo_private_dns_zone_links" {
  type = map(object({
    name                 = string
    private_dns_zone_id  = string
    virtual_network_key  = string
    registration_enabled = optional(bool, false)
    resolution_policy    = optional(string, "Default")
    tags                 = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    Map of VNet links to existing (BYO) Private DNS Zones. Each links an existing DNS zone (by
    resource ID) to a VNet created by this pattern (by map key).

    For creating Private DNS Zones as part of this pattern, use private_dns_zones instead.

    Uses: Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link v0.5.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-privatednszone/azurerm

    - name:                 Link name.
    - private_dns_zone_id:  Resource ID of the existing Private DNS Zone to link.
    - virtual_network_key:  Key in virtual_networks map identifying the VNet.
    - registration_enabled: Enable auto-registration. Default: false.
    - resolution_policy:    Resolution policy. Default: "Default".
    - tags:                 Per-link tags, merged with var.tags.
  EOT
}

variable "managed_identities" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    tags               = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      scope                                  = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, null)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of user-assigned managed identities to create.

    Uses: Azure/avm-res-managedidentity-userassignedidentity/azurerm v0.4.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-managedidentity-userassignedidentity/azurerm

    - name:               Identity name.
    - resource_group_key: Key in resource_groups map for placement.
    - location:           Azure region. Defaults to var.location.
    - tags:               Per-identity tags, merged with var.tags.
    - role_assignments:   Per-identity RBAC assignments.
                          See AVM module variable: role_assignments.
  EOT
}

variable "key_vaults" {
  type = map(object({
    name                          = string
    resource_group_key            = string
    location                      = optional(string)
    sku_name                      = optional(string, "premium")
    public_network_access_enabled = optional(bool, false)
    purge_protection_enabled      = optional(bool, true)
    soft_delete_retention_days    = optional(number, null)
    network_acls = optional(object({
      bypass                     = optional(string, "None")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = optional(string)
      managed_identity_key       = optional(string)
      description                = optional(string, null)
      principal_type             = optional(string, null)
    })), {})
    private_endpoints = optional(map(object({
      name = optional(string, null)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      private_dns_zone = optional(object({
        resource_ids = optional(set(string))
        keys         = optional(set(string))
      }))
      tags = optional(map(string), null)
    })), {})
    tags = optional(map(string), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of Key Vaults.

    Uses: Azure/avm-res-keyvault-vault/azurerm v0.10.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-keyvault-vault/azurerm

    - name:                          Key Vault name.
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - sku_name:                      SKU tier. Default: "premium".
    - public_network_access_enabled: Default: false (secure-by-default, overrides AVM default).
    - purge_protection_enabled:      Default: true.
    - soft_delete_retention_days:    Soft-delete retention. Default: null (AVM default).
    - network_acls:                  Network ACL configuration. Default: bypass=None, action=Deny.
    - role_assignments:              Per-Key-Vault RBAC assignments. Supports principal_id (direct)
                                     or managed_identity_key (from managed_identities map).
                                     Exactly one must be set per assignment.
    - private_endpoints:             Private endpoint configurations.
                                     See AVM module variable: private_endpoints.
    - tags:                          Per-Key-Vault tags, merged with var.tags.
    - diagnostic_settings:           Per-Key-Vault diagnostic settings. Each entry can send
                                     logs/metrics to a Log Analytics workspace, storage account,
                                     Event Hub, or partner solution. workspace_resource_id defaults
                                     to the pattern's LAW (BYO or auto-created) but can be
                                     overridden per entry.
  EOT

  validation {
    condition = alltrue([
      for kv_key, kv in var.key_vaults : alltrue([
        for ra_key, ra in kv.role_assignments : (ra.principal_id != null) != (ra.managed_identity_key != null)
      ])
    ])
    error_message = "Each Key Vault role assignment must set exactly one of principal_id or managed_identity_key."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name = string
    scope                      = string
    principal_id               = optional(string)
    managed_identity_key       = optional(string)
    description                = optional(string, null)
    principal_type             = optional(string, null)
  }))
  default     = {}
  description = <<-EOT
    Standalone role assignments at arbitrary scopes (not scoped to an AVM-managed resource).

    Uses: Azure/avm-res-authorization-roleassignment/azurerm v0.3.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-authorization-roleassignment/azurerm

    - role_definition_id_or_name: Role name or ID.
    - scope:                      Azure resource ID scope for the assignment.
    - principal_id:               Direct principal ID. Mutually exclusive with managed_identity_key.
    - managed_identity_key:       Key in managed_identities map. Mutually exclusive with principal_id.
    - description:                Optional description for the assignment.
    - principal_type:             Optional principal type hint.
  EOT

  validation {
    condition     = alltrue([for k, ra in var.role_assignments : (ra.principal_id != null) != (ra.managed_identity_key != null)])
    error_message = "Each standalone role assignment must set exactly one of principal_id or managed_identity_key."
  }
}

variable "virtual_hub_ids" {
  type        = map(string)
  default     = {}
  description = "Map of Virtual Hub resource IDs by hub key (typically from the root connectivity module output). Used to avoid hard-coding vHub resource IDs in tfvars."
}

variable "vhub_connectivity_definitions" {
  type = map(object({
    vhub_resource_id = optional(string)
    vhub_key         = optional(string)
    virtual_network = object({
      key         = optional(string)
      resource_id = optional(string)
    })
    internet_security_enabled = optional(bool, true)
    routing = optional(object({
      associated_route_table_id = string
      propagated_route_table = optional(object({
        route_table_ids = optional(list(string), [])
        labels          = optional(list(string), [])
      }))
      static_vnet_route = optional(object({
        name                = optional(string)
        address_prefixes    = optional(list(string), [])
        next_hop_ip_address = optional(string)
      }))
    }))
  }))
  default     = {}
  description = <<-EOT
    Map of vWAN hub connections. Each entry links a spoke VNet to a vWAN hub.

    Uses: Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-network-connection v0.13.5
    See:  https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm

    - vhub_resource_id:          Resource ID of the target Virtual Hub (optional).
    - vhub_key:                  Hub key used to look up the Virtual Hub resource ID from
                   virtual_hub_ids (optional). Use this instead of hard-coding
                   a full resource ID in tfvars.
    - virtual_network:           Reference the spoke VNet by key (from virtual_networks map) or by
                                 resource ID. Exactly one of key or resource_id must be set.
    - internet_security_enabled: Route internet traffic through hub firewall. Default: true
                                 (secure-by-default).
    - routing:                   Optional routing configuration for the connection.
      - associated_route_table_id: Resource ID of the Virtual Hub Route Table to associate.
      - propagated_route_table:    Optional propagation config.
        - route_table_ids:         List of Virtual Hub Route Table resource IDs to propagate to.
        - labels:                  List of labels to propagate to.
      - static_vnet_route:         Optional static VNet route.
        - name:                    Name for the static route.
        - address_prefixes:        List of address prefixes.
        - next_hop_ip_address:     Next hop IP address.

    Empty map = no vWAN connections (implicit toggle).
  EOT

  validation {
    condition     = alltrue([for k, v in var.vhub_connectivity_definitions : (try(v.vhub_resource_id, null) != null) || (try(v.vhub_key, null) != null)])
    error_message = "Each vhub_connectivity_definition must set either vhub_resource_id or vhub_key."
  }

  validation {
    condition = alltrue([
      for k, v in var.vhub_connectivity_definitions : (
        try(v.vhub_key, null) == null
        ? true
        : contains(keys(var.virtual_hub_ids), v.vhub_key)
      )
    ])
    error_message = "Each vhub_connectivity_definition vhub_key must exist in virtual_hub_ids."
  }

  validation {
    condition     = alltrue([for k, v in var.vhub_connectivity_definitions : (v.virtual_network.key != null) != (v.virtual_network.resource_id != null)])
    error_message = "Each vhub_connectivity_definition must set exactly one of virtual_network.key or virtual_network.resource_id."
  }
}

variable "bastion_hosts" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    sku                = optional(string, "Standard")
    zones              = optional(set(string), ["1", "2", "3"])
    ip_configuration = optional(object({
      name = optional(string)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      create_public_ip                 = optional(bool, true)
      public_ip_tags                   = optional(map(string), null)
      public_ip_merge_with_module_tags = optional(bool, true)
      public_ip_address_name           = optional(string, null)
      public_ip_address_id             = optional(string, null)
    }))
    virtual_network = optional(object({
      resource_id = optional(string)
      key         = optional(string)
    }))
    copy_paste_enabled        = optional(bool, true)
    file_copy_enabled         = optional(bool, false)
    ip_connect_enabled        = optional(bool, false)
    kerberos_enabled          = optional(bool, false)
    private_only_enabled      = optional(bool, false)
    scale_units               = optional(number, 2)
    session_recording_enabled = optional(bool, false)
    shareable_link_enabled    = optional(bool, false)
    tunneling_enabled         = optional(bool, false)
    tags                      = optional(map(string), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of Azure Bastion Host configurations, keyed by a user-chosen identifier.
    Empty map = no Bastion hosts deployed.

    Uses: Azure/avm-res-network-bastionhost/azurerm v0.9.0
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-bastionhost/azurerm

    - name:                    Bastion name (required).
    - resource_group_key:      Key in resource_groups map for placement.
    - location:                Azure region. Defaults to var.location.
    - sku:                     SKU tier. Default: "Standard".
    - zones:                   Availability zones. Default: ["1","2","3"] (zone-redundant).
    - ip_configuration:        Required for non-Developer SKUs. Provide subnet_resource_id
                               directly, or use vnet_key + subnet_key to resolve from
                               virtual_networks map.
    - virtual_network:         For Developer SKU only. Omit ip_configuration. Provide
                               resource_id directly or key to resolve from virtual_networks map.
    - role_assignments:        Per-Bastion RBAC assignments.
                               See AVM module variable: role_assignments.
    - diagnostic_settings:     Per-Bastion diagnostic settings. Each entry can send logs/metrics
                               to a Log Analytics workspace, storage account, Event Hub, or
                               partner solution. workspace_resource_id defaults to the pattern's
                               LAW (BYO or auto-created) but can be overridden per entry.
    - tags:                    Per-Bastion tags, merged with var.tags.
  EOT
}

# ──────────────────────────────────────────────────────────────
# Storage Accounts
# ──────────────────────────────────────────────────────────────

variable "storage_accounts" {
  type = map(object({
    name                            = string
    resource_group_key              = string
    location                        = optional(string)
    account_tier                    = optional(string, "Standard")
    account_replication_type        = optional(string, "ZRS")
    account_kind                    = optional(string, "StorageV2")
    access_tier                     = optional(string, "Hot")
    shared_access_key_enabled       = optional(bool, false)
    public_network_access_enabled   = optional(bool, false)
    https_traffic_only_enabled      = optional(bool, true)
    min_tls_version                 = optional(string, "TLS1_2")
    allow_nested_items_to_be_public = optional(bool, false)
    network_rules = optional(object({
      bypass                     = optional(set(string), ["AzureServices"])
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(set(string), [])
      virtual_network_subnet_ids = optional(set(string), [])
    }), {})
    managed_identities = optional(object({
      system_assigned            = optional(bool, false)
      user_assigned_resource_ids = optional(set(string), [])
    }), {})
    containers = optional(map(object({
      name          = string
      public_access = optional(string, "None")
      metadata      = optional(map(string))
    })), {})
    private_endpoints = optional(map(object({
      name = optional(string, null)
      network_configuration = object({
        subnet_resource_id = optional(string)
        vnet_key           = optional(string)
        subnet_key         = optional(string)
      })
      subresource_name = string
      private_dns_zone = optional(object({
        resource_ids = optional(set(string))
        keys         = optional(set(string))
      }))
      tags = optional(map(string), null)
    })), {})
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
    tags = optional(map(string), {})
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      storage_account_resource_id              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
  }))
  default     = {}
  description = <<-EOT
    Map of storage accounts to create. The map key is used as a reference key
    (e.g. by flowlog_configuration.flow_logs.storage_account_key).

    Uses: Azure/avm-res-storage-storageaccount/azurerm v0.6.7
    See:  https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm

    - name:                          Storage account name (must be globally unique).
    - resource_group_key:            Key in resource_groups map for placement.
    - location:                      Azure region. Defaults to var.location.
    - account_tier:                  Tier. Default: "Standard".
    - account_replication_type:      Replication. Default: "ZRS".
    - account_kind:                  Kind. Default: "StorageV2".
    - access_tier:                   Access tier. Default: "Hot".
    - shared_access_key_enabled:     Default: false (Entra-only auth).
    - public_network_access_enabled: Default: false (secure-by-default).
    - network_rules:                 Network ACL configuration. Default: bypass AzureServices, deny.
    - managed_identities:            System/user-assigned identity configuration.
    - containers:                    Map of blob containers.
    - private_endpoints:             Private endpoint configurations.
    - role_assignments:              Per-storage RBAC assignments.
    - lock:                          Resource lock. Overrides var.lock.
    - tags:                          Per-storage tags, merged with var.tags.
    - diagnostic_settings:           Per-storage-account diagnostic settings. Each entry can send
                                     logs/metrics to a Log Analytics workspace, storage account,
                                     Event Hub, or partner solution. workspace_resource_id defaults
                                     to the pattern's LAW (BYO or auto-created) but can be
                                     overridden per entry.
  EOT
}

# ──────────────────────────────────────────────────────────────
# Network Watcher / Flow Logs
# ──────────────────────────────────────────────────────────────

variable "flowlog_configuration" {
  type = object({
    network_watcher_id   = optional(string)
    network_watcher_name = optional(string)
    resource_group_name  = optional(string)
    location             = optional(string)
    flow_logs = optional(map(object({
      enabled  = bool
      name     = string
      vnet_key = string
      retention_policy = object({
        days    = number
        enabled = bool
      })
      storage_account = object({
        resource_id = optional(string)
        key         = optional(string)
      })
      traffic_analytics = optional(object({
        enabled               = bool
        interval_in_minutes   = optional(number)
        workspace_id          = optional(string)
        workspace_region      = optional(string)
        workspace_resource_id = optional(string)
      }))
      version = optional(number)
    })), null)
    tags = optional(map(string), {})
  })
  default     = null
  description = <<-EOT
    Network Watcher and VNet flow log configuration. When null (default), no Network Watcher or
    flow logs are configured (implicit toggle).

    Uses: Azure/avm-res-network-networkwatcher/azurerm v0.3.2
    See:  https://registry.terraform.io/modules/Azure/avm-res-network-networkwatcher/azurerm

    - network_watcher_id:   Resource ID of the existing Network Watcher. Defaults to the Azure
                            auto-created NetworkWatcher_<location> in NetworkWatcherRG.
    - network_watcher_name: Name of the existing Network Watcher. Defaults to
                            NetworkWatcher_<location>.
    - resource_group_name:  Resource group containing the Network Watcher. Defaults to
                            NetworkWatcherRG.
    - location:             Azure region. Defaults to var.location.
    - flow_logs:            Map of VNet flow log configurations. Each requires vnet_key (key in
                            virtual_networks map), retention_policy, and storage_account. Provide
                            either storage_account.resource_id (direct) or storage_account.key
                            (reference to storage_accounts map). Optional traffic_analytics —
                            workspace_id, workspace_region, and workspace_resource_id default to
                            values from the pattern's Log Analytics workspace (internal or BYO).
    - tags:                 Per-resource tags, merged with var.tags.
  EOT
}