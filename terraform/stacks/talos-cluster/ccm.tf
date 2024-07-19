resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "talos-ccm"

  privileges = [
    "VM.Audit"
  ]
}

resource "proxmox_virtual_environment_user" "ccm" {
  user_id = "talos-ccm@pve"

  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm.role_id
  }

  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "ccm" {
  user_id    = proxmox_virtual_environment_user.ccm.user_id
  token_name = "ccm"
  comment    = "Managed by Terraform"
}
