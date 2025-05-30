# TODO: import SSH keys
# TODO: implement VRF for services
# TODO: implement ROMON when resource is available
# TODO: routerboard auto upgrade

locals {
  mgmt_cidr = "${var.mgmt_cidr_prefix}/${var.mgmt_cidr_bits}"
}

resource "routeros_system_identity" "self" {
  name = var.hostname
}

# resource "routeros_interface_list" "mgmt" {
#   name = "list-mgmt"
# }
#
# resource "routeros_interface_list_member" "mgmt_port" {
#   list      = routeros_interface_list.mgmt.name
#   interface = var.oob_mgmt_port
# }
#
# resource "routeros_interface_list_member" "mgmt_vlan" {
#   list      = routeros_interface_list.mgmt.name
#   interface = routeros_interface_vlan.mgmt.name
# }

resource "routeros_interface_vlan" "mgmt" {
  name      = "vlan-mgmt"
  interface = var.bridge_name
  vlan_id   = var.mgmt_vlan_id
}

resource "routeros_ip_address" "mgmt" {
  interface = routeros_interface_vlan.mgmt.name
  address   = "${cidrhost(local.mgmt_cidr, var.mgmt_hostnum)}/${var.mgmt_cidr_bits}"
}

# TODO: remove when we have OSPF?
resource "routeros_ip_route" "gateway" {
  dst_address = "0.0.0.0/0"
  gateway     = cidrhost(local.mgmt_cidr, 1)
}
