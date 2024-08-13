variable "proxmox_csi_enable" {
  type    = bool
  default = true
}

resource "proxmox_virtual_environment_role" "csi" {
  count = var.proxmox_csi_enable ? 1 : 0

  role_id = "talos-csi"

  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}

resource "proxmox_virtual_environment_user" "csi" {
  count = var.proxmox_csi_enable ? 1 : 0

  user_id = "talos-csi@pve"

  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi[0].role_id
  }

  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "csi" {
  count = var.proxmox_csi_enable ? 1 : 0

  user_id               = proxmox_virtual_environment_user.csi[0].user_id
  token_name            = "csi"
  comment               = "Managed by Terraform"
  privileges_separation = false
}

resource "truenas_dataset" "democratic_csi" {
  count = var.proxmox_csi_enable ? 1 : 0

  pool = "tank"
  name = "talos"
}

resource "truenas_dataset" "democratic_csi_volumes" {
  count = var.proxmox_csi_enable ? 1 : 0

  pool   = "tank"
  name   = "volumes"
  parent = truenas_dataset.democratic_csi[0].name
}

resource "truenas_dataset" "democratic_csi_snapshots" {
  count = var.proxmox_csi_enable ? 1 : 0

  pool   = "tank"
  name   = "snapshots"
  parent = truenas_dataset.democratic_csi[0].name
}
