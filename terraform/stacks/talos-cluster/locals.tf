locals {
  cidr                    = var.vlan_cidrs[var.vlan_id]
  controlplane_vip        = cidrhost(local.cidr, var.controlplane_ip_offset)
  controlplane_node_count = 3
  controlplane_node_names = [for _, idx in range(local.controlplane_node_count) : "talos-cp-${idx + 1}"]
  controlplane_node_infos = {
    for _, idx in range(local.controlplane_node_count) : local.controlplane_node_names[idx] => {
      ip        = cidrhost(local.cidr, var.controlplane_ip_offset + idx + 1)
      vm_id     = var.vlan_id * 1000 + var.controlplane_ip_offset + idx + 1
      node_name = "pve1"
    }
  }
  controlplane_node_ips = values({ for k, v in local.controlplane_node_infos : k => v.ip })
}

# locals {
#   pod_cidr = "10.244.0.0/16" # Talos default, only needed for native routing
#   lb_cidr  = "10.0.42.0/24"
#
#   ros_addr_list = "local_network"
#   ros_allowed_cidrs = [
#     local.pod_cidr,
#     local.lb_cidr,
#   ]
# }
