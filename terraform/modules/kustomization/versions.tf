terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}
