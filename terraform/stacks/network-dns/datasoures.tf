data "sops_file" "routeros" {
  source_file = "${path.module}/../../../secrets/routeros.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "powerdns" {
  source_file = "${path.module}/../../../secrets/pdns.sops.yaml"
  input_type  = "yaml"
}
