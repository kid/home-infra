include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/kairos"
}

inputs = merge(
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/proxmox.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/kairos.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/pdns.sops.yaml")),
  {
    cluster_name = "kairos.kidibox.net"
    kairos_os_variant = "debian-testing"
    kairos_version = "v3.0.11"
    kairos_k3s_version = "v1.29.3"
    kairos_checksum = "1b7d96bd48105c2eef70d3834860cb14b775123d2f4d488528abf2ff23f1e68d"
  }
)
