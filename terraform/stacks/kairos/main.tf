variable "cluster_name" {
  type = string
}

variable "vlan_id" {
  type    = number
  default = 30
}

variable "vlan_cidrs" {
  type = map(string)
  default = {
    30 = "10.0.30.0/24"
  }
}

variable "controlplane_ip_offset" {
  type    = number
  default = 30
}

variable "worker_ip_offset" {
  type    = number
  default = 40
}

variable "k3s_token" {
  type      = string
  default   = "K10f29d6a6ce07173bf790d01d20aa6e1fcd27763caa6ab113f828c6adf775e0b91::server:c58b8ddbcefcd740b9a8edf64df5172b"
  sensitive = true
}

locals {
  cidr                    = var.vlan_cidrs[var.vlan_id]
  controlplane_node_count = 1
  controlplane_node_names = [for _, idx in range(local.controlplane_node_count) : "kairos-cp-${idx}"]
  controlplane_node_infos = {
    for _, idx in range(local.controlplane_node_count) : local.controlplane_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.controlplane_ip_offset + idx)
      vm_id     = var.vlan_id * 1000 + var.controlplane_ip_offset + idx
      node_name = "pve1"
    }
  }
  cluster_endpoint = local.controlplane_node_infos[local.controlplane_node_names[0]].ip

  worker_node_count = length(var.k3s_token) > 0 ? 2 : 0
  worker_node_names = [for _, idx in range(local.worker_node_count) : "kairos-${idx}"]
  worker_node_infos = {
    for _, idx in range(local.worker_node_count) : local.worker_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.worker_ip_offset + idx)
      vm_id     = var.vlan_id * 1000 + var.worker_ip_offset + idx
      node_name = "pve1"
    }
  }

  ros_addr_list = "local_network"
  ros_allowed_cidrs = [
    "10.42.0.0/16",
    "192.168.42.0/24",
  ]
}

resource "routeros_ip_firewall_addr_list" "local_network" {
  for_each = toset(local.ros_allowed_cidrs)
  list     = local.ros_addr_list
  address  = each.value
}

resource "proxmox_virtual_environment_download_file" "iso" {
  # url = "https://github.com/siderolabs/talos/releases/download/v1.6.7/metal-amd64.iso"
  # url = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.6.7/metal-amd64.iso"
  url = "https://github.com/kairos-io/kairos/releases/download/v3.0.7/kairos-debian-testing-standard-amd64-generic-v3.0.7-k3sv1.29.3+k3s1.iso"
  # url                     = "https://factory.talos.dev/image/c208d9c0b6acc007b9aef846346af92ab4a5dfb5f946db8ff435c16141859f2e/v1.6.7/nocloud-amd64.raw.xz"
  # url                     = "https://github.com/siderolabs/talos/releases/download/v1.6.7/nocloud-amd64.raw.xz"
  # file_name    = "talos2-metal-amd64-v1.7.0.iso"
  # TODO: open PR on proxmox provider
  file_name          = "kairos-debian-testing-standard-amd64-generic-v3.0.7-k3sv1.29.3_k3s1.iso"
  content_type       = "iso"
  node_name          = "pve1"
  datastore_id       = "local"
  overwrite          = true
  checksum           = "5ff2f1370119a17ddf4d88c1a1e195b9800e1e0cb336fb3e0ced6485e42c7f15"
  checksum_algorithm = "sha256"
}

# import {
#   to = proxmox_virtual_environment_download_file.iso
#   id = "pve1:local/iso/kairos-debian-testing-standard-amd64-generic-v3.0.6-k3sv1.27.9_k3s1.iso"
# }

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

  vm_id     = each.value.vm_id
  name      = each.key
  node_name = each.value.node_name
  # bios      = "seabios"
  bios          = "ovmf"
  machine       = "q35"
  tablet_device = false
  boot_order    = ["virtio0", "ide0", "net0"]
  tags          = sort(["terraform", "kairos", "controlplane"])

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

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.iso.id
    interface = "ide0"
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    size         = 20
    file_format  = "raw"
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config_cp[each.key].id
    datastore_id      = "local-zfs"
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
    replace_triggered_by = [proxmox_virtual_environment_file.cloud_config_cp]
  }
}

resource "routeros_ip_dhcp_server_lease" "agent" {
  for_each = {
    for k, v in local.worker_node_infos : k => {
      ip       = v.ip
      ip_parts = split(".", v.ip)
    }
  }

  comment     = each.key
  address     = each.value.ip
  mac_address = format("bc:24:11:%02x:%02x:%02x", each.value.ip_parts[1], each.value.ip_parts[2], each.value.ip_parts[3])
}
resource "proxmox_virtual_environment_vm" "agent" {
  depends_on = [proxmox_virtual_environment_vm.controlplane]
  for_each   = local.worker_node_infos

  vm_id     = each.value.vm_id
  name      = each.key
  node_name = each.value.node_name
  # bios      = "seabios"
  bios          = "ovmf"
  machine       = "q35"
  tablet_device = false
  boot_order    = ["virtio0", "ide0", "net0"]
  tags          = sort(["terraform", "kairos", "agent"])

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

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.iso.id
    interface = "ide0"
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    size         = 20
    file_format  = "raw"
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.key].id
    datastore_id      = "local-zfs"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = var.vlan_id
    mac_address = upper(routeros_ip_dhcp_server_lease.agent[each.key].mac_address)
  }

  # tpm_state {
  #   datastore_id = "local-zfs"
  # }

  serial_device {}

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.cloud_config]
  }
}


resource "proxmox_virtual_environment_file" "cloud_config_cp" {
  for_each     = local.controlplane_node_infos
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml", {
      hostname  = each.key,
      k3s_token = "w92pic.uhwuqre42pa5c7bf"
    })
    file_name = "${each.key}-cloud-config.yaml"
  }
}


resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each     = local.worker_node_infos
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  source_raw {
    data = templatefile("${path.module}/cloud-init-worker.yaml", {
      hostname  = each.key,
      k3s_token = var.k3s_token
    })
    file_name = "${each.key}-cloud-config-worker.yaml"
  }
}

resource "routeros_routing_bgp_connection" "controlplane" {
  for_each         = local.controlplane_node_infos
  name             = each.key
  as               = 64512
  routing_table    = "main"
  address_families = "ip"

  local {
    role = "ebgp"
  }

  remote {
    address = each.value.ip
  }

  output {
    default_originate = "always"
  }
}

resource "routeros_routing_bgp_connection" "worker" {
  for_each         = local.worker_node_infos
  name             = each.key
  as               = 64512
  routing_table    = "main"
  address_families = "ip"

  local {
    role = "ebgp"
  }

  remote {
    address = each.value.ip
  }

  output {
    default_originate = "always"
  }
}
