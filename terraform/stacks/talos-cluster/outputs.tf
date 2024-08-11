output "talosconfig" {
  value     = data.talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive = true
}

output "kubernetes_host" {
  value = "https://${local.controlplane_vip}:6443"
}

output "kubernetes_client_certificate" {
  value = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate
}

output "kubernetes_client_key" {
  value     = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key
  sensitive = true
}

output "kubernetes_ca_certificate" {
  value = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate
}
