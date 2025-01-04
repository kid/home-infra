terraform {
  required_version = ">= 1.8.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.72.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.1.1"
    }
  }
}
