locals {
  subnet_bits = split("/", var.vlan_cidr)[1]
}

resource "routeros_interface_vlan" "self" {
  name      = var.vlan_name
  vlan_id   = var.vlan_id
  interface = var.bridge_name
  mtu       = var.vlan_mtu
}

resource "routeros_interface_bridge_vlan" "self" {
  bridge   = var.bridge_name
  vlan_ids = [var.vlan_id]
  tagged   = concat([var.bridge_name], var.tagged_ifces)
}

resource "routeros_ip_address" "self" {
  interface = routeros_interface_vlan.self.name
  address   = "${cidrhost(var.vlan_cidr, 1)}/${local.subnet_bits}"
}
