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

resource "azurerm_firewall" "this" {
  count = var.create_firewall ? 1 : 0

  name                = coalesce(var.firewall_name, "${var.name}-firewall")
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "AZFW_Hub"
  sku_tier = var.firewall_sku_tier

  virtual_hub {
    virtual_hub_id = module.hub.resource["hub"].id
  }

  firewall_policy_id = var.firewall_policy_id

  tags = local.firewall_tags

  lifecycle {
    precondition {
      condition     = var.create_firewall == false || var.firewall_policy_id != null
      error_message = "When create_firewall=true, firewall_policy_id must be provided."
    }
  }
}
