variable "cilium_enable" {
  type    = bool
  default = true
}

variable "flux_enable" {
  type    = bool
  default = true
}

locals {
  cilium_values = {
    k8sServiceHost = "localhost"
    k8sServicePort = 7445
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
  }
  flux_values = {
    watchAllNamespaces = false
    sourceController = {
      tolerations = local.tolerations
    }
    helmController = {
      tolerations = local.tolerations
    }
    kustomizeController = {
      tolerations = local.tolerations
    }
    notificationController = {
      tolerations = local.tolerations
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
    cli = {
      tolerations = local.tolerations
    }
  }

  tolerations = [{
    key      = "node.cloudprovider.kubernetes.io/uninitialized"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}

resource "helm_release" "cilium" {
  count      = var.cilium_enable ? 1 : 0
  depends_on = [data.talos_cluster_health.cluster]
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.15.7"
  namespace  = "kube-system"

  values = [
    yamlencode(local.cilium_values)
  ]
}

resource "kubernetes_namespace" "flux_system" {
  count      = var.flux_enable ? 1 : 0
  depends_on = [data.talos_cluster_health.cluster]

  metadata {
    name = "flux-system"
    labels = {
      # "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "flux_system" {
  count      = var.flux_enable ? 1 : 0
  depends_on = [helm_release.cilium]

  name       = "flux-system"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.13.0"
  namespace  = kubernetes_namespace.flux_system[0].metadata[0].name
  values = [
    yamlencode(local.flux_values)
  ]
}

resource "helm_release" "flux_sync" {
  count      = var.flux_enable ? 1 : 0
  depends_on = [helm_release.flux_system]

  name       = "flux-sync"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.9.0"
  namespace  = kubernetes_namespace.flux_system[0].metadata[0].name
  values = [
    yamlencode({
      gitRepository = {
        spec = {
          url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
          ref = {
            branch = "main"
          }
          secretRef = {
            name = kubernetes_secret.flux_ssh_key[0].metadata[0].name
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

resource "kubernetes_config_map" "cilium_values" {
  count      = var.flux_enable ? 1 : 0
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "cilium-values"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    "values.yaml" = yamlencode(local.cilium_values)
  }
}

resource "kubernetes_config_map" "flux_values" {
  count      = var.flux_enable ? 1 : 0
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "flux-values"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    "values.yaml" = yamlencode(local.flux_values)
  }
}

# resource "flux_bootstrap_git" "cluster" {
#   count = var.flux_enable ? 1 : 0
#   depends_on = [
#     data.talos_cluster_health.cluster,
#     github_repository_deploy_key.flux,
#     helm_release.cilium,
#     # kubernetes_namespace.flux_system,
#   ]
#   path                   = "clusters/${var.cluster_name}"
#   kustomization_override = file("${path.module}/resources/flux-kustomization-patch.yaml.tftpl")
# }

resource "kubernetes_secret" "flux_ssh_key" {
  count = var.flux_enable ? 1 : 0

  metadata {
    name      = "${var.github_repository}-key"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    identity    = tls_private_key.flux.private_key_pem
    known_hosts = file("${path.module}/files/known_hosts")
  }
}

resource "kubernetes_config_map" "cluster_values" {
  metadata {
    name      = "cluster-values"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    cluster_name         = var.cluster_name
    cluster_domain       = "kidbox.net"
    proxmox_api_endpoint = "${var.proxmox_endpoint}/api2/json"
    proxmox_cluster_name = "pve"
    router_ip            = cidrhost(var.vlan_cidrs[var.vlan_id], 1)
    lb_cidr              = local.lb_cidr
  }
}


resource "kubernetes_secret" "cluster_secrets" {
  metadata {
    name      = "cluster-secrets"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    cloudflare_account_id = var.cloudflare_account_id
    cloudflare_api_token  = var.cloudflare_api_token
    # proxmox_ccm_token_id     = proxmox_virtual_environment_user_token.ccm.id
    # proxmox_ccm_token_secret = trimprefix(proxmox_virtual_environment_user_token.ccm.value, "${proxmox_virtual_environment_user_token.ccm.id}=")
    proxmox_csi_token_id     = proxmox_virtual_environment_user_token.csi.id
    proxmox_csi_token_secret = trimprefix(proxmox_virtual_environment_user_token.csi.value, "${proxmox_virtual_environment_user_token.csi.id}=")
    powerdns_api_url         = var.pdns_api_url
    powerdns_api_key         = var.pdns_api_key
    truenas_host             = var.truenas_host
    truenas_port             = var.truenas_port
    truenas_insecure         = var.truenas_insecure
    truenas_api_key          = var.truenas_api_key
  }
}

resource "random_password" "flux_webhook_token" {
  length  = 32
  special = true
}

resource "kubernetes_secret" "flux_webhook_token" {
  metadata {
    name      = "webhook-token"
    namespace = kubernetes_namespace.flux_system[0].metadata[0].name
  }

  data = {
    token = random_password.flux_webhook_token.result
  }
}

# resource "github_repository_webhook" "flux" {
#   repository = var.github_repository
#
#   configuration {
#     url          = "https://flux-${var.cluster_name}"
#     content_type = "json"
#     secret       = random_password.flux_webhook_token.result
#   }
#
#   active = true
#
#   events = ["push"]
#
#   lifecycle {
#     ignore_changes = [configuration.0.url]
#   }
# }
