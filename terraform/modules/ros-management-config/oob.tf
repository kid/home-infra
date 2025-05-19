locals {
  oob_mgmt_cidr = "${var.oob_mgmt_cidr_prefix}/${var.oob_mgmt_cidr_bits}"
}

resource "routeros_ip_address" "oob" {
  interface = var.oob_mgmt_port
  address   = "${cidrhost(local.oob_mgmt_cidr, 1)}/${var.oob_mgmt_cidr_bits}"
}

module "oob_dhcp" {
  source = "../ros-dhcp"

  interface   = var.oob_mgmt_port
  cidr_prefix = var.oob_mgmt_cidr_prefix
  cidr_bits   = var.oob_mgmt_cidr_bits
}
