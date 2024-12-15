resource "routeros_bridge" "main" {
  name           = var.bridge_name
  frame_types    = "admit-only-vlan-tagged"
  vlan_filtering = true
}
