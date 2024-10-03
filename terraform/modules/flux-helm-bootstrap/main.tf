locals {
  flux_values = {
    watchAllNamespaces = false
    # sourceController = {
    #   tolerations = local.tolerations
    # }
    # helmController = {
    #   tolerations = local.tolerations
    # }
    # kustomizeController = {
    #   tolerations = local.tolerations
    # }
    notificationController = {
      # tolerations = local.tolerations
      container = {
        additionalArgs = ["--rate-limit-interval", "30s", "--feature-gates", "CacheSecretsAndConfigMaps=true"]
      }
    }
    imageAutomationController = {
      create = false
    }
    imageReflectionController = {
      create = false
    }
    # cli = {
    #   tolerations = local.tolerations
    # }
  }

  # tolerations = [{
  #   key      = "node.cloudprovider.kubernetes.io/uninitialized"
  #   operator = "Equal"
  #   value    = "true"
  #   effect   = "NoSchedule"
  # }]
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "github_repository_deploy_key" "flux" {
  title      = "flux@${var.cluster_name}"
  repository = var.github_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = true
}

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
    # labels = {
    #   "pod-security.kubernetes.io/enforce" = "privileged"
    # }
  }
}

resource "kubernetes_secret" "flux_ssh_key" {
  metadata {
    name      = "${var.github_repository}-key"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = {
    identity    = tls_private_key.flux.private_key_pem
    known_hosts = file("${path.module}/files/known_hosts")
  }
}

resource "kubernetes_config_map" "flux_values" {
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "flux-values"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = {
    "values.yaml" = yamlencode(local.flux_values)
  }
}

resource "kubernetes_config_map" "cluster_values" {
  metadata {
    name      = "cluster-values"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = var.cluster_values
}

resource "kubernetes_config_map" "extra" {
  for_each = var.extra_config_maps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = each.value
}

resource "kubernetes_secret" "cluster_secrets" {
  metadata {
    name      = "cluster-secrets"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = var.cluster_secrets
}

resource "helm_release" "flux_system" {
  depends_on = [
    kubernetes_secret.flux_ssh_key,
    kubernetes_secret.cluster_secrets,
    kubernetes_config_map.cluster_values,
    kubernetes_config_map.flux_values,
    kubernetes_config_map.extra,
  ]

  name       = "flux-system"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.14.0"
  namespace  = kubernetes_namespace.flux_system.metadata[0].name
  values = [
    yamlencode(local.flux_values)
  ]
}

resource "helm_release" "flux_sync" {
  depends_on = [helm_release.flux_system]

  name       = "flux-sync"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.9.0"
  namespace  = kubernetes_namespace.flux_system.metadata[0].name
  values = [
    yamlencode({
      gitRepository = {
        spec = {
          url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
          ref = {
            branch = "main"
          }
          secretRef = {
            name = kubernetes_secret.flux_ssh_key.metadata[0].name
          }
        }
      }
      kustomization = {
        spec = {
          path = "clusters/${var.cluster_name}"
        }
      }
    })
  ]
}
