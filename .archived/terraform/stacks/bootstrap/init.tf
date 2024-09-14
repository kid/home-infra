terraform {
  required_version = "1.6.6"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.2.0"
    }
  }
}

variable "use_oidc" {
  type    = bool
  default = false
}

provider "azurerm" {
  features {}

  use_oidc = var.use_oidc
}

provider "azuread" {
  use_oidc = var.use_oidc
}
