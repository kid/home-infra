terraform {
  required_version = ">= 1.8.0"

  required_providers {
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
