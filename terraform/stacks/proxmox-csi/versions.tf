terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
}
