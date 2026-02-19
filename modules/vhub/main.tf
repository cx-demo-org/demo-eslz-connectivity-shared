locals {
  firewall_tags = merge(var.tags, var.firewall_extra_tags)
}

module "hub" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-hub"
  version = "0.13.5"

  # This submodule only creates the Virtual Hub.
  virtual_hubs = {
    hub = {
      name                = var.name
      location            = var.location
      resource_group_name = var.resource_group_name
      address_prefix      = var.address_prefix
      virtual_wan_id      = var.virtual_wan_id
      tags                = var.tags
    }
  }
}

module "firewall" {
  count = var.create_firewall ? 1 : 0

  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = coalesce(var.firewall_name, "${var.name}-firewall")
  location            = var.location
  resource_group_name = var.resource_group_name

  firewall_sku_name = "AZFW_Hub"
  firewall_sku_tier = var.firewall_sku_tier

  # Avoid forcing replacement for existing zone-less firewalls.
  firewall_zones = []

  firewall_virtual_hub = {
    virtual_hub_id = module.hub.resource["hub"].id
  }

  firewall_policy_id = var.firewall_policy_id

  tags = local.firewall_tags

  enable_telemetry = false
}

moved {
  from = azurerm_firewall.this[0]
  to   = module.firewall[0].azurerm_firewall.this
}

check "firewall_policy_required" {
  assert {
    condition     = var.create_firewall == false || var.firewall_policy_id != null
    error_message = "When create_firewall=true, firewall_policy_id must be provided."
  }
}
