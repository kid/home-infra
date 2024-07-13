terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.1"
    }
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.54.2"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.60.0"
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

provider "dns" {
  update {
    server        = "10.0.5.53"
    key_name      = "terraform."
    key_algorithm = var.bind_tsig_keys["terraform"].algorithm
    key_secret    = var.bind_tsig_keys["terraform"].secret
  }
}

locals {
  records = [
    { name = "pve0", ip = "10.0.10.10" },
    { name = "pve1", ip = "10.0.10.11" },
    { name = "ha", ip = "10.0.10.101" },
    { name = "plex", ip = "10.0.30.100" },
    { name = "prowlarr", ip = "10.0.30.110" },
    { name = "radarr", ip = "10.0.30.120" },
    { name = "sonarr", ip = "10.0.30.130" },
    { name = "animarr", ip = "10.0.30.140" },
    { name = "sabnzbd", ip = "10.0.30.150" },
  ]
}

resource "dns_a_record_set" "local" {
  for_each = { for record in local.records : record.name => record }

  zone      = "kidibox.net."
  name      = each.value.name
  addresses = [each.value.ip]

  lifecycle {
    ignore_changes = [ttl]
  }
}
