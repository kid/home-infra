data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = {
    names = [
      "siderolabs/qemu-guest-agent"
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
}

resource "routeros_dns_record" "api_server" {
  name = "api.${var.cluster_domain}"
  type = "A"
  # address = local.controlplane_node_ips[0]
  address = local.controlplane_vip
}

resource "proxmox_virtual_environment_download_file" "iso" {
  url          = data.talos_image_factory_urls.this.urls.iso
  file_name    = "talos-${var.talos_version}-nocloud-amd64.iso"
  content_type = "iso"
  node_name    = "pve1"
  datastore_id = "local"
  overwrite    = false
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
  boot_order    = ["scsi0", "ide0", "net0"]
  tags          = sort(["terraform", "talos", "controlplane"])

  cpu {
    type  = "x86-64-v2-AES"
    cores = 2
  }

  memory {
    dedicated = 4098
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  scsi_hardware = "virtio-scsi-single"

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
    interface    = "scsi0"
    file_format  = "raw"
    size         = 20
    iothread     = true
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = var.vlan_id
    mac_address = upper(routeros_ip_dhcp_server_lease.controlplane[each.key].mac_address)
  }

  tpm_state {
    datastore_id = "local-zfs"
  }

  serial_device {}

  lifecycle {
    ignore_changes = [cpu[0].architecture]
  }
}
