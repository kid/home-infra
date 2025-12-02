resource "macaddress" "router" {}

resource "routeros_ip_dhcp_server_lease" "router" {
  address     = "10.0.10.191"
  mac_address = macaddress.router.address
}

resource "proxmox_virtual_environment_vm" "router" {
  vm_id = 1991
  name  = "lab-router"
  tags  = ["terraform", "routeros"]

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
    mac_address = upper(routeros_ip_dhcp_server_lease.router.mac_address)
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 1991
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port1.name
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 2995
  }

  provisioner "local-exec" {
    interpreter = ["expect", "-c"]
    command     = templatefile("./ros-setup.exp", { ip = routeros_ip_dhcp_server_lease.router.address })
  }
}
