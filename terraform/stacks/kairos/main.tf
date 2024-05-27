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

variable "kairos_os_variant" {
  type    = string
  default = "rockylinux-9"
}

variable "kairos_version" {
  type    = string
  default = "v3.0.8"
}

variable "kairos_k3s_version" {
  type    = string
  default = "v1.29.3"
}

variable "kairos_checksum" {
  type    = string
  default = "0e34caac4273c39c1ba641b3067b7b73eb420d3a8c40fafae81313d637c41ca5"
}

variable "kairos_p2p_token" {
  sensitive = true
}

variable "flux_sops_key" {
  type      = string
  sensitive = true
}

locals {
  cidr                    = var.vlan_cidrs[var.vlan_id]
  controlplane_node_count = 1
  controlplane_node_names = [for _, idx in range(local.controlplane_node_count) : "kairos-cp-${idx + 1}"]
  controlplane_node_infos = {
    for _, idx in range(local.controlplane_node_count) : local.controlplane_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.controlplane_ip_offset + idx + 1)
      vm_id     = var.vlan_id * 1000 + var.controlplane_ip_offset + idx + 1
      node_name = "pve1"
    }
  }

  worker_node_count = 1
  worker_node_names = [for _, idx in range(local.worker_node_count) : "kairos-${idx}"]
  worker_node_infos = {
    for _, idx in range(local.worker_node_count) : local.worker_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.worker_ip_offset + idx)
      vm_id     = var.vlan_id * 1000 + var.worker_ip_offset + idx
      node_name = "pve1"
    }
  }

  kubevip_eip = cidrhost(local.cidr, var.controlplane_ip_offset)

  ros_addr_list = "local_network"
  ros_allowed_cidrs = [
    "10.42.0.0/16",
    "10.0.43.0/24",
  ]
}

resource "routeros_ip_firewall_addr_list" "local_network" {
  for_each = toset(local.ros_allowed_cidrs)
  list     = local.ros_addr_list
  address  = each.value
}


resource "proxmox_virtual_environment_download_file" "iso" {
  url = "https://github.com/kairos-io/kairos/releases/download/${var.kairos_version}/kairos-${var.kairos_os_variant}-standard-amd64-generic-${var.kairos_version}-k3s${var.kairos_k3s_version}+k3s1.iso"
  # TODO: open PR on proxmox provider
  file_name          = "kairos-${var.kairos_os_variant}-standard-amd64-generic-${var.kairos_version}-k3sv${var.kairos_k3s_version}_k3s1.iso"
  content_type       = "iso"
  node_name          = "pve1"
  datastore_id       = "local"
  overwrite          = true
  checksum           = var.kairos_checksum
  checksum_algorithm = "sha256"
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
    replace_triggered_by = [
      proxmox_virtual_environment_download_file.iso,
      proxmox_virtual_environment_file.cloud_config_cp,
    ]
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
  for_each = local.worker_node_infos

  vm_id         = each.value.vm_id
  name          = each.key
  node_name     = each.value.node_name
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
    replace_triggered_by = [
      proxmox_virtual_environment_download_file.iso,
      proxmox_virtual_environment_file.cloud_config,
      proxmox_virtual_environment_vm.controlplane
    ]
  }
}

resource "proxmox_virtual_environment_file" "cloud_config_cp" {
  for_each     = local.controlplane_node_infos
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml", {
      role             = "master"
      hostname         = each.key,
      kairos_p2p_token = var.kairos_p2p_token,
      kubevip_eip      = local.kubevip_eip
      flux_sops_key    = var.flux_sops_key
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
    data = templatefile("${path.module}/cloud-init-agent.yaml", {
      role             = "worker"
      hostname         = each.key,
      kairos_p2p_token = var.kairos_p2p_token,
      kubevip_eip      = local.kubevip_eip
    })
    file_name = "${each.key}-cloud-config-worker.yaml"
  }
}

resource "routeros_routing_bgp_connection" "bgp" {
  for_each         = merge(local.controlplane_node_infos, local.worker_node_infos)
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
