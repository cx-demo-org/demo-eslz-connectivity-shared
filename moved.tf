moved {
  from = module.virtual_wan[0].module.this.azurerm_virtual_wan.virtual_wan
  to   = module.alz_connectivity.module.virtual_wan[0].azurerm_virtual_wan.virtual_wan
}

moved {
  from = module.virtual_hubs["prod"].module.hub.azurerm_virtual_hub.virtual_hub["hub"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_hubs.azurerm_virtual_hub.virtual_hub["prod"]
}

moved {
  from = module.virtual_hubs["prod"].module.firewall[0].azurerm_firewall.this
  to   = module.alz_connectivity.module.virtual_wan[0].module.firewalls.azurerm_firewall.fw["prod"]
}

moved {
  from = module.virtual_hubs["prod_eu"].module.hub.azurerm_virtual_hub.virtual_hub["hub"]
  to   = module.alz_connectivity.module.virtual_wan[0].module.virtual_hubs.azurerm_virtual_hub.virtual_hub["prod_eu"]
}

moved {
  from = module.virtual_hubs["prod_eu"].module.firewall[0].azurerm_firewall.this
  to   = module.alz_connectivity.module.virtual_wan[0].module.firewalls.azurerm_firewall.fw["prod_eu"]
}
