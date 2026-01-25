resource "azurerm_resource_group" "hub" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Shared vWAN state (created by msft-vwan-prod stack)
data "terraform_remote_state" "vwan" {
  backend = "local"
  config = {
    path = "C:/LocalApps/GithubWorkspaces/cx-statestore/msft-vwan-prod/terraform.tfstate"
  }
}

# Firewall policy state (managed as its own stack in Option B)
data "terraform_remote_state" "fwpolicy" {
  backend = "local"
  config = {
    path = "C:/LocalApps/GithubWorkspaces/cx-statestore/msft-fwpolicy-prod/terraform.tfstate"
  }
}

module "connectivity_virtual_hub" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-hub"
  version = "0.13.5"

  # This submodule only creates the Virtual Hub.
  virtual_hubs = {
    hub = {
      name                = var.virtual_hub_name
      location            = var.location
      resource_group_name = azurerm_resource_group.hub.name
      address_prefix      = var.hub_address_prefix
      virtual_wan_id      = data.terraform_remote_state.vwan.outputs.virtual_wan_id
      tags                = var.tags
    }
  }
}

# Azure Firewall in Virtual Hub (secured hub) deployed separately.
# NOTE: This requires the Firewall SKU that supports Virtual Hub (AZFW_Hub).
resource "azurerm_firewall" "hub" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name

  sku_name = "AZFW_Hub"
  sku_tier = "Standard"

  # This links the firewall to the Virtual Hub.
  virtual_hub {
    virtual_hub_id = module.connectivity_virtual_hub.resource["hub"].id
  }

  firewall_policy_id = data.terraform_remote_state.fwpolicy.outputs.firewall_policy_id

  tags = var.tags
}
