terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
    }
  }
}
