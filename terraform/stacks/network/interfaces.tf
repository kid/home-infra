resource "routeros_interface_bridge" "bridge" {
  name              = "bridge1"
  vlan_filtering    = true
  ingress_filtering = true
  frame_types       = "admit-only-vlan-tagged"
  protocol_mode     = "rstp"
}

resource "routeros_interface_vlan" "vlan" {
  for_each  = local.vlans
  name      = each.key
  interface = routeros_interface_bridge.bridge.name
  vlan_id   = each.value.id
}

resource "routeros_interface_bridge_port" "ports" {
  for_each  = local.ports
  comment   = lookup(each.value, "comment", null)
  bridge    = routeros_interface_bridge.bridge.name
  interface = each.key
  pvid      = lookup(each.value, "pvid", 1)
  frame_types = lookup(each.value, "frame_types",
    lookup(each.value, "pvid", 1) > 1 && length(lookup(each.value, "tagged", [])) > 0
    ? "admit-all"
    : length(lookup(each.value, "tagged", [])) > 0
    ? "admit-only-vlan-tagged"
    : "admit-only-untagged-and-priority-tagged"
  )
  hw = true
}

resource "routeros_interface_bridge_vlan" "vlans" {
  for_each = local.vlans
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [tostring(each.value.id)]
  tagged = concat(
    [routeros_interface_bridge.bridge.name],
    [for k, v in local.ports : k if contains(lookup(v, "tagged", []), each.value.id)]
  )
}
