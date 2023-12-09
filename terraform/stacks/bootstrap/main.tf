terraform {
  required_version = "1.6.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.85.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "container_name" {
  type = string
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                             = var.storage_account_name
  location                         = azurerm_resource_group.tfstate.location
  resource_group_name              = azurerm_resource_group.tfstate.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
}

resource "azurerm_storage_container" "tfstate" {
  storage_account_name = azurerm_storage_account.tfstate.name
  name                 = var.container_name
}

data "azurerm_client_config" "current" {}

locals {
  resource_group_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
}

import {
  to = azurerm_resource_group.tfstate
  id = local.resource_group_id
}

import {
  to = azurerm_storage_account.tfstate
  id = "${local.resource_group_id}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}"
}

import {
  to = azurerm_storage_container.tfstate
  id = "https://${var.storage_account_name}/${var.container_name}"
}
