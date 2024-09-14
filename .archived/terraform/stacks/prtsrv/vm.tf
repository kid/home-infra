locals {
  vm_name   = "prtsrv"
  node_name = "pve1"
}

resource "proxmox_virtual_environment_file" "cloudconfig" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.node_name

  source_raw {
    file_name = "${local.vm_name}-ignition.ign"
    data      = data.ignition_config.vm.rendered
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name = local.vm_name
  tags = ["terraform"]

  node_name     = local.node_name
  bios          = "seabios"
  machine       = "q35"
  tablet_device = false
  boot_order    = ["virtio0"]

  cpu {
    type  = "x86-64-v2-AES"
    cores = 4
  }

  memory {
    dedicated = 1024
    shared    = 1024
    floating  = 512
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    trim    = true
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    size         = 20
    file_id      = var.flatcar_image_id
    file_format  = "raw"
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 100
  }

  usb {
    host = "04f9:0027"
    usb3 = false
  }

  kvm_arguments = "-fw_cfg name=opt/com.coreos/config,file=/var/lib/vz/snippets/${local.vm_name}-ignition.ign"

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.cloudconfig]
  }
}
