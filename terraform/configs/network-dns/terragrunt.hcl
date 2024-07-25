include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/network-dns"

  # Powerdns does not like parallelism with Sqlite backend
  extra_arguments "parallelism" {
    commands =  ["apply", "destroy"]
    arguments = ["-parallelism=1"]
  }
}

inputs = merge(
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/routeros.sops.yaml")),
  yamldecode(sops_decrypt_file("${get_repo_root()}/secrets/pdns.sops.yaml")),
  {
    domain_name = "kidibox.net"
  }
)
