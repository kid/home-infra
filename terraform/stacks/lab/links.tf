resource "proxmox_virtual_environment_network_linux_bridge" "port1" {
  node_name = "pve1"
  name      = "vmbr1001"
}

resource "proxmox_virtual_environment_network_linux_bridge" "port2" {
  node_name = "pve1"
  name      = "vmbr1002"
}
