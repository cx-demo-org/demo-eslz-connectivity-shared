locals {
  # Clean lookup maps for day-0 usability.
  #
  # These locals intentionally only do:
  # - key -> id/name lookups
  # - "effective input" shaping (prefer explicit IDs, otherwise derive from keys)

  resource_group_resource_ids = merge(
    { for key, mod in module.resource_groups : key => mod.resource_id },
    { for key, rg in data.azurerm_resource_group.rg : key => rg.id }
  )

  firewall_policy_ids = merge(
    { for key, mod in module.firewall_policies : key => mod.resource_id },
    { for key, fp in data.azurerm_firewall_policy.existing : key => fp.id }
  )

  network_security_group_ids = merge(
    { for key, nsg in module.network_security_groups : key => nsg.resource_id },
    { for key, nsg in data.azurerm_network_security_group.existing : key => nsg.id }
  )

  # RBAC role assignments: allow either `scope` or `scope_resource_group_key`.
  role_assignments_azure_resource_manager_effective = {
    for assignment_key, assignment in var.role_assignments_azure_resource_manager : assignment_key => merge(
      # Strip helper key before passing through to AVM
      { for k, v in assignment : k => v if k != "scope_resource_group_key" },

      # Hydrate scope from resource group key when scope is not explicitly set
      (
        try(assignment.scope, null) != null ? {}
        : try(assignment.scope_resource_group_key, null) != null ? { scope = local.resource_group_resource_ids[assignment.scope_resource_group_key] }
        : {}
      )
    )
  }

  # Virtual hub input shaping: allow key-based references while keeping AVM schema.
  # Supported helper keys:
  # - default_parent_resource_group_key -> default_parent_id
  # - firewall.firewall_policy_key -> firewall.firewall_policy_id
  # - sidecar_virtual_network.subnets[*].network_security_group.key -> ...id
  virtual_hubs_effective = {
    for hub_key, hub in var.virtual_hubs : hub_key => merge(
      # Strip helper key from the root hub object (if present)
      { for k, v in hub : k => v if k != "default_parent_resource_group_key" },

      # Hydrate default_parent_id if not explicitly provided
      (
        try(hub.default_parent_id, null) != null ? {}
        : try(hub.default_parent_resource_group_key, null) != null ? { default_parent_id = local.resource_group_resource_ids[hub.default_parent_resource_group_key] }
        : {}
      ),

      # Hydrate firewall.firewall_policy_id if using a firewall_policy_key
      (
        try(hub.firewall, null) == null ? {}
        : {
          firewall = merge(
            { for k, v in hub.firewall : k => v if k != "firewall_policy_key" },
            (
              try(hub.firewall.firewall_policy_id, null) != null ? {}
              : try(hub.firewall.firewall_policy_key, null) != null ? { firewall_policy_id = local.firewall_policy_ids[hub.firewall.firewall_policy_key] }
              : {}
            )
          )
        }
      ),

      # Hydrate sidecar subnet NSG IDs if using a network_security_group.key
      (
        try(hub.sidecar_virtual_network, null) == null ? {}
        : {
          sidecar_virtual_network = merge(
            hub.sidecar_virtual_network,
            (
              try(hub.sidecar_virtual_network.subnets, null) == null ? {}
              : {
                subnets = {
                  for subnet_key, subnet in hub.sidecar_virtual_network.subnets : subnet_key => merge(
                    subnet,
                    (
                      try(subnet.network_security_group, null) == null ? {}
                      : {
                        network_security_group = merge(
                          { for k, v in subnet.network_security_group : k => v if k != "key" },
                          (
                            try(subnet.network_security_group.id, null) != null ? {}
                            : try(subnet.network_security_group.key, null) != null ? { id = local.network_security_group_ids[subnet.network_security_group.key] }
                            : {}
                          )
                        )
                      }
                    )
                  )
                }
              }
            )
          )
        }
      )
    )
  }
}
