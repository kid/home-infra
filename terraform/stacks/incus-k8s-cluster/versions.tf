terraform {
  required_version = ">= 1.8.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    incus = {
      source  = "lxc/incus"
      version = "0.3.1"
    }
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.85.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.2"
    }
  }
}
