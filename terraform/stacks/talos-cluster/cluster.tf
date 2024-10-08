resource "talos_machine_secrets" "cluster" {
  talos_version = var.talos_version

  lifecycle {
    ignore_changes = [talos_version]
  }
}

data "talos_machine_configuration" "controlplane" {
  for_each         = local.controlplane_node_infos
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.controlplane_node_infos[local.controlplane_node_names[0]].ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  talos_version    = var.talos_version
  # TODO: set kubernetes_version
}

output "machine_config" {
  value     = data.talos_machine_configuration.controlplane["talos-cp-1"].machine_configuration
  sensitive = true
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = local.controlplane_node_infos
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  node                        = each.value.ip
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  config_patches = [
    # TODO: split this in per feature patches
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
          disk       = "/dev/sda"
          image      = "ghcr.io/siderolabs/installer:${var.talos_version}"
          extensions = [for ext in data.talos_image_factory_extensions_versions.this.extensions_info : { image = ext.ref }]
        }
        features = {
          hostDNS = {
            enabled = true
            # FIXME: This is causing issues with Flux client
            # forwardKubeDNSToHost = true
          }
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
          endpoint = "https://${trimsuffix(powerdns_record.api.name, ".")}:6443"
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

resource "powerdns_record" "api" {
  name = "api.${var.cluster_domain}."

  zone    = "kidibox.net."
  type    = "LUA"
  ttl     = 60
  records = ["A \"ifportup(6443, {{'${local.controlplane_vip}'}, {'${local.controlplane_node_ips[0]}'}})\""]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  node                 = values({ for k, v in local.controlplane_node_infos : k => v.ip })[0]
  client_configuration = talos_machine_secrets.cluster.client_configuration
}


resource "talos_cluster_kubeconfig" "cluster" {
  depends_on           = [talos_machine_bootstrap.cluster]
  node                 = values({ for k, v in local.controlplane_node_infos : k => v.ip })[0]
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

# tflint-ignore: terraform_unused_declarations
data "talos_cluster_health" "cluster" {
  depends_on             = [talos_machine_bootstrap.cluster]
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
