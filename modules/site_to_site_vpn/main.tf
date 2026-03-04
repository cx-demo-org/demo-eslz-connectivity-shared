locals {
  vpn_gateways_effective = {
    for key, gw in var.vpn_gateways : key => merge(gw, {
      location            = var.location
      resource_group_name = var.resource_group_name
      virtual_hub_id      = var.virtual_hub_id
      tags                = merge(var.tags, try(gw.tags, {}))
    })
  }

  vpn_sites_effective = {
    for key, site in var.vpn_sites : key => merge(site, {
      location            = var.location
      resource_group_name = var.resource_group_name
      virtual_wan_id      = var.virtual_wan_id
      tags                = merge(var.tags, try(site.tags, {}))
    })
  }
}

module "vpn_gateways" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/site-to-site-gateway"
  version = "0.13.5"

  vpn_gateways = local.vpn_gateways_effective
}

module "vpn_sites" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/site-to-site-vpn-site"
  version = "0.13.5"

  vpn_sites = local.vpn_sites_effective
}

locals {
  vpn_site_links_by_site = {
    for site_key, links in module.vpn_sites.links : site_key => {
      for link in links : link.name => link.id
    }
  }

  vpn_site_connections_effective = {
    for conn_key, conn in var.vpn_site_connections : conn_key => merge(conn, {
      remote_vpn_site_id = module.vpn_sites.resource_id[conn.vpn_site_key]
      vpn_gateway_id     = module.vpn_gateways.resource_object[conn.vpn_gateway_key].id
      vpn_links = [
        for link in conn.vpn_links : merge(link, {
          vpn_site_link_id = local.vpn_site_links_by_site[conn.vpn_site_key][link.vpn_site_link_name]
        })
      ]
    })
  }
}

module "vpn_site_connections" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/site-to-site-gateway-connection"
  version = "0.13.5"

  vpn_site_connection = local.vpn_site_connections_effective
}
