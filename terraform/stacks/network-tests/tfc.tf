terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "kid"

    workspaces {
      project = "home-infra"
      name    = "network-tests"
    }
  }
}
