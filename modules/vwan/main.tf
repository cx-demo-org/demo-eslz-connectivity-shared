module "this" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-wan"
  version = "0.13.5"

  enable_telemetry = var.enable_module_telemetry
  tags             = var.tags

  virtual_wan_name    = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.sku

  allow_branch_to_branch_traffic = var.allow_branch_to_branch_traffic
  disable_vpn_encryption         = var.disable_vpn_encryption
}
