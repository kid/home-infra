variable "wan_iface" {
  type = string
}

variable "mgmt_port" {
  type = string
}

variable "cidr" {
  type = string
}

variable "cidr_new_bits" {
  type    = number
  default = 8
}

variable "vlans" {
  type = map(object({
    vlan_id = number
    mtu     = optional(number)
  }))

  default = {
    adm = {
      vlan_id = 99
    }
    srv = {
      vlan_id = 10
    }
    data = {
      vlan_id = 20
      mtu     = 9000
    }
    lan = {
      vlan_id = 100
    }
  }
}

variable "interfaces" {
  type = map(object({
    pvid  = optional(number)
    vlans = optional(list(number), [])
  }))

  default = {
    ether2 = {
      pvid = 99
      # comment = "mgmt-port"
    }
    ether3 = {
      pvid = 100
    }
    ether4 = {
      pvid = 10
    }
    # ether4 = {
    #   pvid = 99
    # }
    # ether5 = {
    #   pvid = 99
    #   vlans = [10, 20]
    # }
  }
}

locals {
  vlan_tagged_ifces = {
    for vlan_name, vlan in var.vlans : vlan_name => [
      for ifce_name, ifce in var.interfaces :
      ifce_name if contains(ifce.vlans, vlan.vlan_id) && ifce.pvid != vlan.vlan_id
    ]
  }
}

# resource "routeros_bridge" "main" {
#   name           = "bridge1"
#   frame_types    = "admit-only-vlan-tagged"
#   vlan_filtering = true
# }

resource "routeros_bridge_port" "main" {
  depends_on  = [module.vlans]
  for_each    = var.interfaces
  bridge      = module.base_cfg.bridge_name
  interface   = each.key
  pvid        = each.value.pvid
  frame_types = each.value.pvid != null ? "admit-only-untagged-and-priority-tagged" : "admit-only-vlan-tagged"
}

module "vlans" {
  source       = "../../modules/ros-vlan"
  for_each     = var.vlans
  bridge_name  = module.base_cfg.bridge_name
  vlan_name    = each.key
  vlan_id      = each.value.vlan_id
  vlan_cidr    = cidrsubnet(var.cidr, var.cidr_new_bits, each.value.vlan_id)
  vlan_mtu     = lookup(each.value, "mtu", null)
  tagged_ifces = local.vlan_tagged_ifces[each.key]
}

resource "routeros_interface_list" "wan" {
  name = "WAN"
}

resource "routeros_interface_list_member" "wan" {
  list      = routeros_interface_list.wan.name
  interface = var.wan_iface
}

resource "routeros_interface_list" "local" {
  name = "LOCAL"
}

resource "routeros_interface_list_member" "local_vlans" {
  for_each  = var.vlans
  list      = routeros_interface_list.local.name
  interface = module.vlans[each.key].interface
}

resource "routeros_interface_list" "mgmt" {
  name = "MGMT"
}

resource "routeros_interface_list_member" "mgmt" {
  list      = routeros_interface_list.mgmt.name
  interface = module.vlans["adm"].interface
}

resource "routeros_interface_list_member" "mgmt_port" {
  list      = routeros_interface_list.mgmt.name
  interface = var.mgmt_port
}
