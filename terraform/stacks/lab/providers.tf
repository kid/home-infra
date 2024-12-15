provider "sops" {}

data "sops_file" "proxmox" {
  source_file = "${path.module}/../../../secrets/proxmox.sops.yaml"
  input_type  = "yaml"
}

provider "proxmox" {
  endpoint = data.sops_file.proxmox.data.proxmox_endpoint
  username = data.sops_file.proxmox.data.proxmox_username
  password = data.sops_file.proxmox.data.proxmox_password
  insecure = data.sops_file.proxmox.data.proxmox_insecure
}

data "sops_file" "routeros" {
  source_file = "${path.module}/../../../secrets/routeros.sops.yaml"
  input_type  = "yaml"
}

provider "routeros" {
  hosturl  = data.sops_file.routeros.data.routeros_endpoint
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}
