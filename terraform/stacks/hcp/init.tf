terraform {
  required_version = ">= 1.6.6"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.28.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.43.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
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
