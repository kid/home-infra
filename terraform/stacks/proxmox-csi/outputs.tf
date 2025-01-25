output "proxmox_url" {
  value     = "${data.sops_file.proxmox.data.proxmox_endpoint}/api2/json"
  sensitive = true
}

output "proxmox_token_id" {
  value     = proxmox_virtual_environment_user_token.csi.id
  sensitive = true
}

output "proxmox_token_secret" {
  value     = trimprefix(proxmox_virtual_environment_user_token.csi.value, "${proxmox_virtual_environment_user_token.csi.id}=")
  sensitive = true
}

output "proxmox_region" {
  value = "pve"
}
