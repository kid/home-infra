# TODO: set router identity
# TODO: import SSH keys
# TODO: add dhcp-server on management subnet
# TODO: add dhcp-client on admin vlan
# TODO: implement VRF for services

locals {
  oob_mgmt_cidr = "${var.oob_mgmt_cidr_prefix}/${var.oob_mgmt_cidr_bits}"
}

resource "routeros_interface_list" "admin" {
  name = "admin-ifces"
}

resource "routeros_interface_list_member" "admin_interface" {
  list      = routeros_interface_list.admin.name
  interface = var.oob_mgmt_interface
}

resource "routeros_interface_list_member" "admin_vlan" {
  list      = routeros_interface_list.admin.name
  interface = routeros_interface_vlan.admin.name
}

resource "routeros_interface_vlan" "admin" {
  interface = var.bridge_name
  name      = "admin-vlan"
  vlan_id   = var.mgmt_vlan_id
}

resource "routeros_ip_address" "oob" {
  interface = var.oob_mgmt_interface
  address   = "${cidrhost(local.oob_mgmt_cidr, 1)}/${var.oob_mgmt_cidr_bits}"
}

module "oob_dhcp" {
  source = "../ros-dhcp"

  interface   = var.oob_mgmt_interface
  cidr_prefix = var.oob_mgmt_cidr_prefix
  cidr_bits   = var.oob_mgmt_cidr_bits
}
