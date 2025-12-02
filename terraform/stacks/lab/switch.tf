resource "macaddress" "switch" {}

resource "routeros_ip_dhcp_server_lease" "switch" {
  address     = "10.0.10.192"
  mac_address = macaddress.switch.address
}

resource "proxmox_virtual_environment_vm" "switch" {
  vm_id = 1992
  name = "lab-switch"
  tags = ["terraform", "routeros"]

  node_name = "pve1"

  agent {
    enabled = true
  }

  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.chr.id
    file_format  = "raw"
    interface    = "scsi0"
    size         = 10
    iothread     = true
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 10
    mac_address = upper(routeros_ip_dhcp_server_lease.switch.mac_address)
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 1992
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port1.name
  }

  provisioner "local-exec" {
    interpreter = ["expect", "-c"]
    command     = templatefile("./ros-setup.exp", { ip = routeros_ip_dhcp_server_lease.switch.address })
  }
}
