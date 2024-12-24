terraform {
  required_version = ">= 1.8.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.66.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.68.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0"
    }
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.1.1"
    }
  }
}
