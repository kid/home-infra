resource "routeros_routing_bgp_connection" "bgp" {
  for_each         = local.controlplane_node_infos
  name             = each.key
  as               = 64512
  routing_table    = "main"
  address_families = "ip"

  local {
    role = "ibgp"
  }

  remote {
    address = each.value.ip
  }

  output {
    default_originate = "always"
  }
}

resource "routeros_ip_firewall_addr_list" "local_network" {
  for_each = toset(local.ros_allowed_cidrs)
  list     = local.ros_addr_list
  address  = each.value
}
