data "sops_file" "proxmox" {
  source_file = "${path.module}/../../../secrets/proxmox.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "routeros" {
  source_file = "${path.module}/../../../secrets/routeros.sops.yaml"
  input_type  = "yaml"
}
