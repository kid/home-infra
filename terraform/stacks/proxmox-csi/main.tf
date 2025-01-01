resource "proxmox_virtual_environment_role" "csi" {
  role_id = "proxmox-csi-${var.cluster_name}"

  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}

resource "proxmox_virtual_environment_user" "csi" {
  user_id = "proxmox-csi-${var.cluster_name}@pve"

  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }

  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "csi" {
  user_id               = proxmox_virtual_environment_user.csi.user_id
  token_name            = "csi"
  comment               = "Managed by Terraform"
  privileges_separation = false
}
