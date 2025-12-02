resource "proxmox_virtual_environment_download_file" "chr" {
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = "pve1"
  url                     = "https://download.mikrotik.com/routeros/7.20rc1/chr-7.20rc1.img.zip"
  file_name               = "chr-7.16.img"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve1"
  url          = "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.raw"
  file_name    = "debian-13-nocloud-amd64-daily.img"
  # url          = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

# resource "proxmox_virtual_environment_vm" "lan1" {
#   name      = "lab-lan1"
#   node_name = "pve1"
#
#   initialization {
#     datastore_id = "local-zfs"
#
#     user_account {
#       username = "admin"
#       password = "admin"
#     }
#   }
#
#   disk {
#     datastore_id = "local-zfs"
#     file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
#     file_format  = "raw"
#     interface    = "virtio0"
#     iothread     = true
#     discard      = "on"
#     size         = 20
#   }
#
#   network_device {
#     bridge = proxmox_virtual_environment_network_linux_bridge.port1.name
#   }
# }

# resource "proxmox_virtual_environment_vm" "srv1" {
#   name      = "lab-srv1"
#   node_name = "pve1"
#
#   initialization {
#     datastore_id = "local-zfs"
#
#     user_account {
#       username = "admin"
#       password = "admin"
#     }
#   }
#
#   disk {
#     datastore_id = "local-zfs"
#     file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
#     file_format  = "raw"
#     interface    = "virtio0"
#     iothread     = true
#     discard      = "on"
#     size         = 20
#   }
#
#   network_device {
#     bridge = proxmox_virtual_environment_network_linux_bridge.port2.name
#   }
# }
