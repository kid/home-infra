terraform {
  required_version = "1.6.6"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.28.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.43.0"
    }
  }
}
