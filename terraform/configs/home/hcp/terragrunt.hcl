include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/hcp"
}

inputs = merge(
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/proxmox.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/consul.sops.yaml")),
  {
    environment = "home"
  },
)
