locals {
  roles = {
    push = {
      subject_string = "ref:refs/heads/main"
      # storage_role_definition_id = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      storage_role_definition_id = "17d1049b-9a84-46fb-8f53-869881c3d3ab"
    }
    pr = {
      subject_string             = "pull_request"
      storage_role_definition_id = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
    }
  }
}

resource "azuread_application_registration" "gha" {
  display_name = "home-infra"
}


resource "azuread_application_federated_identity_credential" "gha" {
  for_each       = local.roles
  application_id = azuread_application_registration.gha.id
  display_name   = "${azuread_application_registration.gha.display_name}-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:kid/home-infra:${each.value.subject_string}"
}

resource "azuread_service_principal" "gha" {
  # for_each  = local.roles
  client_id = azuread_application_registration.gha.client_id
}

resource "azurerm_role_assignment" "storage" {
  # for_each           = local.roles
  scope              = azurerm_storage_account.tfstate.id
  principal_id       = azuread_service_principal.gha.id
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.roles.push.storage_role_definition_id}"
}

output "gha_id" {
  value = azuread_application_registration.gha.id
}
output "gha_client_id" {
  value = azuread_application_registration.gha.client_id
}
