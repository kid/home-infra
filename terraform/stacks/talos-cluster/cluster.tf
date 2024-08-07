resource "talos_machine_secrets" "cluster" {
  talos_version = "v${var.talos_version}"
}

data "talos_machine_configuration" "controlplane" {
  for_each         = local.controlplane_node_infos
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.controlplane_node_infos[local.controlplane_node_names[0]].ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = local.controlplane_node_infos
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  node                        = each.value.ip
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.key
          interfaces = [{
            interface = "eth0"
            dhcp      = true
            vip = {
              ip = local.controlplane_vip
            }
          }]
        }
        install = {
          disk = "/dev/vda"
        }
        nodeLabels = {
          "topology.kubernetes.io/region" = "pve"
          "topology.kubernetes.io/zone"   = each.value.node_name
        }
        # kubelet = {
        #   extraArgs = {
        #     cloud-provider             = "external"
        #     rotate-server-certificates = true
        #   }
        # }
        # features = {
        #   kubernetesTalosAPIAccess = {
        #     enabled                     = true
        #     allowedRoles                = ["os:reader"]
        #     allowedKubernetesNamespaces = ["kube-system"]
        #   }
        # }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        controlPlane = {
          endpoint = "https://${local.controlplane_vip}:6443"
        }
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        # externalCloudProvider = {
        #   enabled = true
        #   manifests = [
        #     "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml"
        #   ]
        # }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.controlplane]
  }
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [talos_machine_configuration_apply.controlplane]
  # for_each             = local.controlplane_node_infos
  node                 = values({ for k, v in local.controlplane_node_infos : k => v.ip })[0]
  client_configuration = talos_machine_secrets.cluster.client_configuration
}


resource "talos_cluster_kubeconfig" "cluster" {
  depends_on           = [talos_machine_bootstrap.cluster]
  node                 = values({ for k, v in local.controlplane_node_infos : k => v.ip })[0]
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

data "talos_cluster_health" "cluster" {
  # depends_on             = [proxmox_virtual_environment_vm.controlplane]
  client_configuration   = talos_machine_secrets.cluster.client_configuration
  endpoints              = values({ for k, v in local.controlplane_node_infos : k => v.ip })
  control_plane_nodes    = values({ for k, v in local.controlplane_node_infos : k => v.ip })
  skip_kubernetes_checks = true
}

data "talos_client_configuration" "cluster" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  nodes                = values({ for k, v in local.controlplane_node_infos : k => v.ip })
  endpoints            = values({ for k, v in local.controlplane_node_infos : k => v.ip })
}

output "talosconfig" {
  value     = data.talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive = true
}


output "machine_configuration" {
  value     = { for k in local.controlplane_node_names : k => data.talos_machine_configuration.controlplane[k].machine_configuration }
  sensitive = true
}
