variable "flux_enable" {
  type    = bool
  default = true
}

module "flux_kustomize" {
  source = "${path.module}/../kustomization"

  resources = [
    "${path.module}/../../../clusters/${var.cluster_name}/flux-system",
  ]
}

resource "kubernetes_config_map" "cluster_values" {
  depends_on = [module.flux_kustomize]

  metadata {
    name      = "cluster-values"
    namespace = "flux-system"
  }

  data = var.cluster_values
}

resource "kubernetes_config_map" "extra" {
  depends_on = [module.flux_kustomize]
  for_each   = var.extra_config_maps

  metadata {
    name      = each.key
    namespace = "flux-system"
  }

  data = each.value
}

resource "kubernetes_secret" "cluster_secrets" {
  depends_on = [module.flux_kustomize]

  metadata {
    name      = "cluster-secrets"
    namespace = "flux-system"
  }

  data = var.cluster_secrets
}

resource "kubernetes_secret" "sops_age" {
  count      = var.sops_age != null ? 1 : 0
  depends_on = [module.flux_kustomize]

  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }

  data = {
    "age.ageKey" = var.sops_age
  }
}
