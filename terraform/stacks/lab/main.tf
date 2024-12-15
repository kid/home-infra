resource "proxmox_virtual_environment_download_file" "chr" {
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = "pve1"
  url                     = "https://download.mikrotik.com/routeros/7.16/chr-7.16.img.zip"
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

resource "macaddress" "router" {}

resource "routeros_ip_dhcp_server_lease" "router" {
  address     = "10.0.10.110"
  mac_address = macaddress.router.address
}

resource "proxmox_virtual_environment_vm" "router" {
  name = "lab-router"
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
    mac_address = upper(routeros_ip_dhcp_server_lease.router.mac_address)
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 1099
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port1.name
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port2.name
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 2995
  }

  provisioner "local-exec" {
    interpreter = ["expect", "-c"]
    command     = file("./ros-setup.exp")
  }
}

resource "proxmox_virtual_environment_network_linux_bridge" "port1" {
  node_name = "pve1"
  name      = "vmbr1001"
}

resource "proxmox_virtual_environment_network_linux_bridge" "port2" {
  node_name = "pve1"
  name      = "vmbr1002"
}

resource "proxmox_virtual_environment_vm" "lan1" {
  name      = "lab-lan1"
  node_name = "pve1"

  initialization {
    datastore_id = "local-zfs"

    user_account {
      username = "admin"
      password = "admin"
    }
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port1.name
  }
}

resource "proxmox_virtual_environment_vm" "srv1" {
  name      = "lab-srv1"
  node_name = "pve1"

  initialization {
    datastore_id = "local-zfs"

    user_account {
      username = "admin"
      password = "admin"
    }
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge = proxmox_virtual_environment_network_linux_bridge.port2.name
  }
}
