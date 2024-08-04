terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.56.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-alpha.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }
  }
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = false
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

variable "routeros_endpoint" {
  type = string
}

variable "routeros_username" {
  type      = string
  sensitive = true
}

variable "routeros_password" {
  type      = string
  sensitive = true
}

variable "routeros_insecure" {
  type    = bool
  default = false
}

provider "routeros" {
  hosturl  = var.routeros_endpoint
  username = var.routeros_username
  password = var.routeros_password
  insecure = var.routeros_insecure
}

provider "kubernetes" {
  host                   = "https://${local.controlplane_vip}:6443"
  client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${local.controlplane_vip}:6443"
    client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
  }
}

variable "github_org" {
  type    = string
  default = "kid"
}

variable "github_repository" {
  type    = string
  default = "home-infra"
}

provider "github" {
  owner = var.github_org
}

variable "cloudflare_account_id" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "pdns_api_url" {
  type = string
}

variable "pdns_api_key" {
  type      = string
  sensitive = true
}

provider "truenas" {
  base_url = "http://${var.truenas_host}/api/v2.0"
  api_key  = var.truenas_api_key
}

resource "truenas_dataset" "democratic_csi" {
  pool = "tank"
  name = "talos"
}

moved {
  from = truenas_dataset.talos
  to   = truenas_dataset.democratic_csi
}

resource "truenas_dataset" "democratic_csi_volumes" {
  pool   = "tank"
  name   = "volumes"
  parent = truenas_dataset.democratic_csi.name
}

resource "truenas_dataset" "democratic_csi_snapshots" {
  pool   = "tank"
  name   = "snapshots"
  parent = truenas_dataset.democratic_csi.name
}
