terraform {
  required_version = ">= 1.8.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.83.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.76.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
}
