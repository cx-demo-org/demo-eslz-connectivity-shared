terraform {
  required_version = ">= 1.9, < 2.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
  }
}

provider "azurerm" {
  subscription_id = (try(trimspace(var.hub_subscription_id), "") != "") ? var.hub_subscription_id : null
  tenant_id       = (try(trimspace(var.hub_tenant_id), "") != "") ? var.hub_tenant_id : null

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias = "wan"

  subscription_id = (
    try(trimspace(var.virtual_wan_subscription_id), "") != ""
    ) ? var.virtual_wan_subscription_id : (
    (try(trimspace(var.hub_subscription_id), "") != "") ? var.hub_subscription_id : null
  )

  tenant_id = (
    try(trimspace(var.virtual_wan_tenant_id), "") != ""
    ) ? var.virtual_wan_tenant_id : (
    (try(trimspace(var.hub_tenant_id), "") != "") ? var.hub_tenant_id : null
  )

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  subscription_id = (try(trimspace(var.hub_subscription_id), "") != "") ? var.hub_subscription_id : null
  tenant_id       = (try(trimspace(var.hub_tenant_id), "") != "") ? var.hub_tenant_id : null
}

provider "azapi" {
  alias = "wan"

  subscription_id = (
    try(trimspace(var.virtual_wan_subscription_id), "") != ""
    ) ? var.virtual_wan_subscription_id : (
    (try(trimspace(var.hub_subscription_id), "") != "") ? var.hub_subscription_id : null
  )

  tenant_id = (
    try(trimspace(var.virtual_wan_tenant_id), "") != ""
    ) ? var.virtual_wan_tenant_id : (
    (try(trimspace(var.hub_tenant_id), "") != "") ? var.hub_tenant_id : null
  )
}
