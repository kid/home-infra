
locals {
  cidr                    = var.vlan_cidrs[var.vlan_id]
  controlplane_vip        = cidrhost(local.cidr, var.controlplane_ip_offset)
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
  url                     = "https://factory.talos.dev/image/${var.talos_schematic_id}/v${var.talos_version}/nocloud-amd64.raw.xz"
  file_name               = "talos-${var.talos_version}-nocloud-amd64.img"
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
  boot_order    = ["virtio0", "net0"]
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

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    file_id      = proxmox_virtual_environment_download_file.image.id
  }

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
    replace_triggered_by = [
      proxmox_virtual_environment_download_file.image,
    ]
  }
}

locals {
  pod_cidr = "10.244.0.0/16" # Talos default, only needed for native routing
  lb_cidr  = "10.0.42.0/24"

  ros_addr_list = "local_network"
  ros_allowed_cidrs = [
    local.pod_cidr,
    local.lb_cidr,
  ]
}

resource "routeros_ip_firewall_addr_list" "local_network" {
  for_each = toset(local.ros_allowed_cidrs)
  list     = local.ros_addr_list
  address  = each.value
}

resource "routeros_routing_bgp_connection" "bgp" {
  for_each         = merge(local.controlplane_node_infos)
  name             = each.key
  as               = 64512
  routing_table    = "main"
  address_families = "ip"

  local {
    role = "ibgp"
  }

  remote {
    address = each.value.ip
  }

  output {
    default_originate = "always"
  }
}
