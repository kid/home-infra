terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.60.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.62.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-alpha.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
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
    powerdns = {
      source  = "pan-net/powerdns"
      version = "1.5.0"
    }
  }
}
