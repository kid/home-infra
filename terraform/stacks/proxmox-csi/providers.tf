provider "sops" {}

provider "proxmox" {
  endpoint = data.sops_file.proxmox.data.proxmox_endpoint
  username = data.sops_file.proxmox.data.proxmox_username
  password = data.sops_file.proxmox.data.proxmox_password
  insecure = data.sops_file.proxmox.data.proxmox_insecure
}
