resource "routeros_ip_neighbor_discovery_settings" "settings" {
  discover_interface_list = routeros_interface_list.mgmt.name
}

resource "routeros_ipv6_neighbor_discovery" "settings" {
  interface = module.vlans["adm"].interface
}

resource "routeros_tool_mac_server" "settings" {
  allowed_interface_list = routeros_interface_list.mgmt.name
}

resource "routeros_tool_mac_server_winbox" "settings" {
  allowed_interface_list = routeros_interface_list.mgmt.name
}
