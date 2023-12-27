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
