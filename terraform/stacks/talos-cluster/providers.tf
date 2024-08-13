provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

provider "routeros" {
  hosturl  = var.routeros_endpoint
  username = var.routeros_username
  password = var.routeros_password
  insecure = var.routeros_insecure
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
  client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kustomization" {
  kubeconfig_raw = talos_cluster_kubeconfig.cluster.kubeconfig_raw
}

provider "github" {
  owner = var.github_org
}

provider "truenas" {
  base_url = "http://${var.truenas_host}/api/v2.0"
  api_key  = var.truenas_api_key
}

provider "powerdns" {
  server_url = var.pdns_api_url
  api_key    = var.pdns_api_key
}
