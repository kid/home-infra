# data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_application_registration" "oidc" {
  display_name = "kid-home-infra-main"
}

resource "azuread_application_federated_identity_credential" "oidc" {
  application_id = azuread_application_registration.oidc.id
  display_name   = azuread_application_registration.oidc.display_name
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:kid/home-infra:ref:refs/heads/main"
}

resource "azuread_service_principal" "oidc" {
  client_id = azuread_application_registration.oidc.client_id
  # owners    = [data.azurerm_client_config.current.subscription_id]
  # owners = [data.azurerm_client_config.current.subscription_id]
}

resource "azurerm_role_assignment" "rg" {
  scope                = azurerm_resource_group.tfstate.id
  principal_id         = azuread_service_principal.oidc.id
  role_definition_name = "Contributor"
}

resource "azurerm_role_assignment" "storage" {
  scope        = azurerm_storage_account.tfstate.id
  principal_id = azuread_service_principal.oidc.id
  # role_definition_name = "Contributor"

  # role_definition_id = "b24988ac-6180-42a0-ab88-20f7382dd24c"
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
}
# resource "azuread_app_role_assignment" "storage" {
#   # scope = data.azuread_client_config.current.id
#   # app_role_id =
#   # principal_object_id = azuread_service_principal.oidc.object_id
#   # resource_object_id =
# }
