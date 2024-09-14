terraform {
  # backend "azurerm" {
  #   resource_group_name  = "home-infra(terraform)"
  #   storage_account_name = "tf67355dd92c904b09bcda72"
  #   container_name       = "tfstate"
  #   key                  = "network-dns/terraform.tfstate"
  #   use_oidc             = true
  # }

  cloud {
    hostname     = "app.terraform.io"
    organization = "kid"

    workspaces {
      project = "home-infra"
      name    = "network-dns"
    }
  }
}
