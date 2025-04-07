data "routeros_interfaces" "ether" {
  filter = {
    type = "ether"
  }
}

locals {
  interface_list = toset([
    for idx, item in data.routeros_interfaces.ether.interfaces : item.name
    if !contains(var.ignore_interfaces, item.name)
  ])
  vlan_ids = distinct(flatten([for _, item in var.bridge_ports : try(item.vlan_ids, [])]))
}

resource "routeros_interface_ethernet" "self" {
  for_each     = local.interface_list
  factory_name = each.key
  name         = each.key
  comment      = try(var.bridge_ports[each.key].comment, null)
}

resource "routeros_interface_bridge" "self" {
  name           = var.bridge_name
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "self" {
  for_each  = local.interface_list
  bridge    = routeros_interface_bridge.self.name
  interface = each.key
  pvid      = try(var.bridge_ports[each.key].pvid, 1)
  comment   = try(var.bridge_ports[each.key].comment, null)
}

resource "routeros_interface_bridge_vlan" "self" {
  for_each = { for id in local.vlan_ids : "vlan${id}" => id }
  bridge   = routeros_interface_bridge.self.name
  vlan_ids = [each.value]
  tagged = concat(
    [routeros_interface_bridge.self.name],
    [for k, v in var.bridge_ports : k if contains(try(v.vlan_ids, []), each.value)]
  )
}

output "debug" {
  value = {
    bridge_ports = var.bridge_ports
    vlan_ids     = local.vlan_ids
    tagged99     = [for k, v in var.bridge_ports : k if contains(try(v.vlan_ids, []), 99)]
  }
}
