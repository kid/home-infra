terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "kid"

    workspaces {
      project = "home-infra"
      name    = "proxmox-csi-${var.cluster_name}"
    }
  }
}
