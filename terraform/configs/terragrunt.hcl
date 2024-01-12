locals {
  bootstrap_inputs = jsondecode(file("./bootstrap/terraform.tfvars.json"))
  # proxmox_secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/proxmox.sops.yaml"))
  # routeros_secrets = yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml"))
}

remote_state {
  backend = "azurerm"

  config = {
    resource_group_name = local.bootstrap_inputs.resource_group_name,
    storage_account_name = local.bootstrap_inputs.storage_account_name
    container_name = local.bootstrap_inputs.container_name
    key = "${path_relative_to_include()}/terraform.tfstate"
    use_oidc = true
  }

  generate = {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  # local.proxmox_secrets,
  # local.routeros_secrets,
  {
    location = local.bootstrap_inputs.location
  }
)
