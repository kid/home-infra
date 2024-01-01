resource "proxmox_virtual_environment_file" "flatcar_img" {
  datastore_id = "local"
  node_name    = "pve1"

  source_file {
    path      = "https://${var.flatcar_channel}.release.flatcar-linux.net/${var.flatcar_arch}/${var.flatcar_release}/flatcar_production_qemu_image.img"
    file_name = "flatcar-production-qemu-${var.flatcar_channel}-${var.flatcar_release}-${var.flatcar_arch}.img"
  }
}
