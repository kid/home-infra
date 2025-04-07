# TODO: add dhcp-server on management subnet
# TODO: add dhcp-client on admin vlan
# TODO: implement VRF for services

resource "routeros_interface_list" "admin" {
  name = "admin-ifces"
}

resource "routeros_interface_list_member" "admin_port" {
  list      = routeros_interface_list.admin.name
  interface = var.oob_mgmt_port
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

resource "routeros_ip_address" "admin" {
  interface = var.oob_mgmt_port
  address   = var.oob_mgmt_address
}
