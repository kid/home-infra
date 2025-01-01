data "sops_file" "proxmox" {
  source_file = "${path.module}/../../../secrets/proxmox.sops.yaml"
  input_type  = "yaml"
}
