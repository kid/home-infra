terraform {
  required_version = ">= 1.9.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.84.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
}
