locals {
  bootstrap_inputs = jsondecode(file("./bootstrap/terraform.tfvars.json"))
}

remote_state {
  backend = "azurerm"

  config = {
    resource_group_name  = local.bootstrap_inputs.resource_group_name,
    storage_account_name = local.bootstrap_inputs.storage_account_name
    container_name       = local.bootstrap_inputs.container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_oidc             = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
