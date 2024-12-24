provider "sops" {}

provider "proxmox" {
  endpoint = data.sops_file.proxmox.data.proxmox_endpoint
  username = data.sops_file.proxmox.data.proxmox_username
  password = data.sops_file.proxmox.data.proxmox_password
  insecure = data.sops_file.proxmox.data.proxmox_insecure
}

provider "routeros" {
  hosturl  = data.sops_file.routeros.data.routeros_endpoint
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}

provider "truenas" {
  base_url = "http://${data.sops_file.truenas.data.truenas_host}/api/v2.0"
  api_key  = data.sops_file.truenas.data.truenas_api_key
}
