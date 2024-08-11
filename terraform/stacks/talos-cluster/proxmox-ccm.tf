variable "proxmox_ccm_enable" {
  type    = bool
  default = false
}

resource "proxmox_virtual_environment_role" "ccm" {
  count = var.proxmox_ccm_enable ? 1 : 0

  role_id = "talos-ccm"

  privileges = [
    "VM.Audit"
  ]
}

resource "proxmox_virtual_environment_user" "ccm" {
  count = var.proxmox_ccm_enable ? 1 : 0

  user_id = "talos-ccm@pve"

  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm[0].role_id
  }

  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "ccm" {
  count = var.proxmox_ccm_enable ? 1 : 0

  user_id               = proxmox_virtual_environment_user.ccm[0].user_id
  token_name            = "ccm"
  comment               = "Managed by Terraform"
  privileges_separation = false
}
