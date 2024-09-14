provider "sops" {}

provider "proxmox" {
  endpoint = data.sops_file.proxmox.data.proxmox_endpoint
  username = data.sops_file.proxmox.data.proxmox_username
  password = data.sops_file.proxmox.data.proxmox_password
  insecure = data.sops_file.proxmox.data.proxmox_insecure
}

provider "routeros" {
  hosturl  = data.sops_file.routeros.data.routeros_endpoint
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}

provider "powerdns" {
  server_url = data.sops_file.powerdns.data.pdns_api_url
  api_key    = data.sops_file.powerdns.data.pdns_api_key
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
  base_url = "http://${data.sops_file.truenas.data.truenas_host}/api/v2.0"
  api_key  = data.sops_file.truenas.data.truenas_api_key
}

