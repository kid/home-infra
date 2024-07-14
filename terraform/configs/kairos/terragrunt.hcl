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
    kairos_version = "v3.1.0"
    kairos_k3s_version = "v1.30.2"
    kairos_checksum = "8f2a1c0d3c704fdd2623430071a532f90d860f52f0cdb2d4964c5fe233bd24fa"
  }
)
