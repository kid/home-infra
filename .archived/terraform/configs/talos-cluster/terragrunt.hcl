include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/talos-cluster"
}

inputs = merge(
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/proxmox.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/truenas.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/cloudflare.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/pdns.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/grafana.sops.yaml")),
  {
    cluster_name   = "talos.kidibox.net"
    cluster_domain = "talos.kidibox.net"
    talos_version  = "v1.7.6"
  }
)
