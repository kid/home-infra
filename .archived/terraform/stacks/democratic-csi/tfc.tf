terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "kid"

    workspaces {
      project = "home-infra"
      name    = "democratic-csi-${var.cluster_name}"
    }
  }
}
