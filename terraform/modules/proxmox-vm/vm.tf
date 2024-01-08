locals {
  ip_split   = split(".", var.ip_address)
  vlan_id    = local.ip_split[2]
  vm_id      = local.ip_split[2] * 100 + local.ip_split[3]
  macaddress = format("bc:24:11:%02x:%02x:%02x", local.ip_split[1], local.ip_split[2], local.ip_split[3])
}

resource "routeros_ip_dhcp_server_lease" "name" {
  address     = var.ip_address
  mac_address = upper(local.macaddress)
}

resource "proxmox_virtual_environment_vm" "data" {
  count = length(var.data_disks) > 0 ? 1 : 0

  name      = "${var.vm_name}-data"
  node_name = var.node_name
  started   = false
  on_boot   = false

  dynamic "disk" {
    for_each = var.data_disks

    content {
      datastore_id = "local-zfs"
      file_format  = "raw"
      interface    = "virtio0"
      size         = disk.value["size"]
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  depends_on = [proxmox_virtual_environment_file.ignition]

  vm_id         = local.vm_id
  name          = var.vm_name
  node_name     = var.node_name
  bios          = "seabios"
  machine       = "q35"
  tablet_device = false
  boot_order    = ["virtio0"]
  tags          = sort(concat(["terraform"], var.tags))

  cpu {
    type  = "x86-64-v2-AES"
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_dedicated
    floating  = var.memory_floating
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    size         = 10
    file_id      = var.root_file_id
    file_format  = "raw"
  }

  dynamic "disk" {
    for_each = { for idx, val in flatten(proxmox_virtual_environment_vm.data[*].disk) : idx => val }
    iterator = data_disk

    content {
      datastore_id      = data_disk.value["datastore_id"]
      path_in_datastore = data_disk.value["path_in_datastore"]
      file_format       = data_disk.value["file_format"]
      size              = data_disk.value["size"]
      interface         = "virtio${data_disk.key + 1}"
    }
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = local.vlan_id
    mac_address = local.macaddress
  }

  kvm_arguments = var.ignition_enabled ? "-fw_cfg name=opt/com.coreos/config,file=/var/lib/vz/snippets/${local.vm_id}-ignition.ign" : null

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.ignition]
  }
}

resource "proxmox_virtual_environment_file" "ignition" {
  count = var.ignition_enabled ? 2 : 0

  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve${count.index}"

  source_raw {
    file_name = "${local.vm_id}-ignition.ign"
    data      = var.ignition_rendered
  }
}
