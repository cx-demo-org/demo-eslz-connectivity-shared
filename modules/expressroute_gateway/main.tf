module "this" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/expressroute-gateway"
  version = "0.13.5"

  expressroute_gateways = {
    gateway = {
      name                = var.name
      location            = var.location
      resource_group_name = var.resource_group_name
      virtual_hub_id      = var.virtual_hub_id

      tags = var.tags

      allow_non_virtual_wan_traffic = var.allow_non_virtual_wan_traffic
      scale_units                   = var.scale_units
    }
  }
}
