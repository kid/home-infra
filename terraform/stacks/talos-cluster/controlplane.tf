
locals {
  cidr                    = var.vlan_cidrs[var.vlan_id]
  controlplane_node_count = 3
  controlplane_node_names = [for _, idx in range(local.controlplane_node_count) : "talos-cp-${idx + 1}"]
  controlplane_node_infos = {
    for _, idx in range(local.controlplane_node_count) : local.controlplane_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.controlplane_ip_offset + idx + 1)
      vm_id     = var.vlan_id * 1000 + var.controlplane_ip_offset + idx + 1
      node_name = "pve1"
    }
  }
}

resource "proxmox_virtual_environment_download_file" "image" {
  url = "https://factory.talos.dev/image/${var.talos_schematic_id}/v${var.talos_version}/metal-amd64.raw.zst"
  # TODO: open PR on proxmox provider
  file_name               = "talos-${var.talos_version}.img"
  decompression_algorithm = "zst"
  content_type            = "iso"
  node_name               = "pve1"
  datastore_id            = "local"
  overwrite               = false
}

resource "routeros_ip_dhcp_server_lease" "controlplane" {
  for_each = {
    for k, v in local.controlplane_node_infos : k => {
      ip       = v.ip
      ip_parts = split(".", v.ip)
    }
  }

  comment     = each.key
  address     = each.value.ip
  mac_address = format("bc:24:11:%02x:%02x:%02x", each.value.ip_parts[1], each.value.ip_parts[2], each.value.ip_parts[3])
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  for_each = local.controlplane_node_infos

  vm_id         = each.value.vm_id
  name          = each.key
  node_name     = each.value.node_name
  bios          = "ovmf"
  machine       = "q35"
  tablet_device = false
  boot_order    = ["virtio0", "ide0", "net0"]
  tags          = sort(["terraform", "talos", "controlplane"])

  cpu {
    type  = "x86-64-v2-AES"
    cores = 4
  }

  memory {
    dedicated = 2048
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  # cdrom {
  #   enabled   = true
  #   file_id   = proxmox_virtual_environment_download_file.iso.id
  #   interface = "ide0"
  # }

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
    type         = "4m"
  }

  # disk {
  #   datastore_id = "local-zfs"
  #   interface    = "virtio0"
  #   size         = 20
  #   file_format  = "raw"
  # }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    file_id      = proxmox_virtual_environment_download_file.image.id
  }

  # initialization {
  #   user_data_file_id = proxmox_virtual_environment_file.cloud_config_cp[each.key].id
  #   datastore_id      = "local-zfs"
  # }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = var.vlan_id
    mac_address = upper(routeros_ip_dhcp_server_lease.controlplane[each.key].mac_address)
  }

  # tpm_state {
  #   datastore_id = "local-zfs"
  # }

  serial_device {}

  lifecycle {
    ignore_changes = [cpu[0].architecture]
    #   replace_triggered_by = [
    #     proxmox_virtual_environment_download_file.iso,
    #     proxmox_virtual_environment_file.cloud_config_cp,
    #   ]
  }
}
