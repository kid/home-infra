output "namespace" {
  value = kubernetes_namespace.flux_system.metadata[0].name
}
