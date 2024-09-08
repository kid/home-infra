variable "cilium_enable" {
  type    = bool
  default = true
}

locals {
  cilium_values = {
    k8sServiceHost    = "localhost"
    k8sServicePort    = 7445
    rollOutCiliumPods = true
    operator = {
      rollOutPods = true
      replicas    = 1
    }
    ipam = {
      mode = "kubernetes"
    }
    kubeProxyReplacement = true
    cgroup = {
      autoMount = {
        enabled = false
      }
      hostRoot = "/sys/fs/cgroup"
    }
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }
    routingMode           = "native"
    ipv4NativeRoutingCIDR = local.pod_cidr
    autoDirectNodeRoutes  = true
    bgpControlPlane = {
      enabled : true
    }
    gatewayAPI = {
      enabled = true
    }
  }
}

# resource "helm_release" "cilium" {
#   count = !var.bootstrap && var.cilium_enable ? 1 : 0
#   depends_on = [
#     data.talos_cluster_health.cluster,
#     # module.gateway_api
#   ]
#
#   name       = "cilium"
#   repository = "https://helm.cilium.io/"
#   chart      = "cilium"
#   version    = "1.15.7"
#   namespace  = "kube-system"
#
#   values = [
#     yamlencode(local.cilium_values)
#   ]
# }

resource "routeros_routing_bgp_connection" "bgp" {
  for_each         = var.cilium_enable ? merge(local.controlplane_node_infos) : {}
  name             = each.key
  as               = 64512
  routing_table    = "main"
  address_families =  "ip"

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
  for_each = var.cilium_enable ? toset(local.ros_allowed_cidrs) : []
  list     = local.ros_addr_list
  address  = each.value
}

# resource "kubernetes_manifest" "cilium_lb_ippool" {
#   count      = !var.bootstrap && var.cilium_enable ? 1 : 0
#   depends_on = [helm_release.cilium]
#
#   manifest = {
#     apiVersion = "cilium.io/v2alpha1"
#     kind       = "CiliumLoadBalancerIPPool"
#     metadata = {
#       name = "bgp-pool"
#     }
#     spec = {
#       cidrs = [
#         { cidr = local.lb_cidr }
#       ]
#     }
#   }
# }
