include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/talos-cluster"
}

inputs = merge(
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/proxmox.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/cloudflare.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/pdns.sops.yaml")),
  {
    cluster_name = "talos.kidibox.net"
    talos_version = "1.7.5"
    talos_schematic_id = "dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586"
  }
)
