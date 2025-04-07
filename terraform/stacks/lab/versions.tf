terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.74.1"
    }
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.76.7"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.2"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.1.1"
    }
  }
}
