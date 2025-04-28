terraform {
  required_version = ">= 1.8.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.83.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
}
