locals {
  cluster_name = "home"
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = ["10.0.30.10"]
  nodes                = ["10.0.30.10"]
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = local.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://10.0.30.10:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# resource "talos_cluster_kubeconfig" "kubeconfig" {
#   depends_on = [
#     talos_machine_bootstrap.this
#   ]
#   client_configuration = talos_machine_secrets.this.client_configuration
#   endpoint             = "10.0.30.100"
#   node                 = "10.0.30.100"
# }

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = "10.0.30.10"
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
          extraKernelArgs = [
            "talos.dashboard.disabled=1"
          ]
        }
        # kernel = {
        #   parameters = [
        #     "talos.dashboard.disabled=1"
        #   ]
        # }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [incus_instance.instance1]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
  node                 = "10.0.30.10"
  client_configuration = talos_machine_secrets.this.client_configuration
}

# data "talos_cluster_health" "health" {
#   depends_on           = [talos_machine_configuration_apply.controlplane]
#   client_configuration = data.talos_client_configuration.this.client_configuration
#   control_plane_nodes  = ["10.0.30.100"]
#   # worker_nodes         = [ var.talos_worker_01_ip_addr ]
#   endpoints = data.talos_client_configuration.this.endpoints
# }

# data "talos_cluster_kubeconfig" "kubeconfig" {
#   depends_on           = [talos_machine_bootstrap.this]
#   client_configuration = talos_machine_secrets.this.client_configuration
#   node                 = "10.0.30.10"
# }

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

# output "kubeconfig" {
#   value     = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
#   sensitive = true
# }
