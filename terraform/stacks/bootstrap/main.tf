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
