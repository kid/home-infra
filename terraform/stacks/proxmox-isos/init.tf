terraform {
  required_version = "1.6.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.42.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}
