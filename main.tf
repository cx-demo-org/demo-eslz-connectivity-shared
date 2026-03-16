## AVM schema pass-through
# This repo intentionally stays close to the upstream AVM pattern module by
# passing `virtual_wan_settings` and `virtual_hubs` through directly.

module "resource_groups" {
  for_each = var.resource_groups

  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags

  enable_telemetry = false
}

data "azurerm_resource_group" "rg" {
  for_each = var.existing_resource_groups

  name = each.value.name
}

module "alz_connectivity" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  providers = {
    azurerm = azurerm.wan
    azapi   = azapi.wan
  }

  enable_telemetry = var.enable_telemetry
  tags             = var.tags

  default_naming_convention          = var.default_naming_convention
  default_naming_convention_sequence = var.default_naming_convention_sequence
  retry                              = var.retry
  timeouts                           = var.timeouts

  private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix = var.private_link_private_dns_zone_virtual_network_link_moved_block_template_module_prefix

  virtual_wan_settings = var.virtual_wan_settings
  virtual_hubs         = local.virtual_hubs_effective
}

