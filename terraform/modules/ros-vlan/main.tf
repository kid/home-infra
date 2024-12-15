locals {
  subnet_bits = split("/", var.vlan_cidr)[1]
  gateway_ip  = cidrhost(var.vlan_cidr, 1)
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
  address   = "${local.gateway_ip}/${local.subnet_bits}"
}

resource "routeros_ip_pool" "self" {
  name   = var.vlan_name
  ranges = ["${cidrhost(var.vlan_cidr, 100)}-${cidrhost(var.vlan_cidr, 254)}"]
}

resource "routeros_ip_dhcp_server" "self" {
  name         = var.vlan_name
  lease_time   = var.dhcp_lease_time
  interface    = routeros_interface_vlan.self.name
  address_pool = routeros_ip_pool.self.name
}

resource "routeros_ip_dhcp_server_network" "self" {
  address    = var.vlan_cidr
  domain     = var.dhcp_domain
  gateway    = local.gateway_ip
  dns_server = length(var.dhcp_dns_servers) > 0 ? var.dhcp_dns_servers : [local.gateway_ip]
}

resource "routeros_interface_list" "self" {
  name = "vlan-${var.vlan_name}"
}

resource "routeros_interface_list_member" "self" {
  list      = routeros_interface_list.self.name
  interface = routeros_interface_vlan.self.name
}
