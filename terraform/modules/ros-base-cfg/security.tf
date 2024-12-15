# resource "routeros_interface_list" "mgmt" {
#   name = "mgmt"
# }
#
# resource "routeros_ip_neighbor_discovery_settings" "self" {
#   discover_interface_list = routeros_interface_list.mgmt.name
# }
#
# resource "routeros_tool_mac_server" "self" {
#   allowed_interface_list = routeros_interface_list.mgmt.name
# }
#
# resource "routeros_tool_mac_server_winbox" "settings" {
#   allowed_interface_list = routeros_interface_list.mgmt.name
# }
