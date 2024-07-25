terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.56.0"
    }
    powerdns = {
      source  = "pan-net/powerdns"
      version = "1.5.0"
    }
  }
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

variable "pdns_api_url" {
  type = string
}

variable "pdns_api_key" {
  type      = string
  sensitive = true
}

variable "pdns_api_key_hash" {
  type      = string
  sensitive = true
}

provider "powerdns" {
  server_url = var.pdns_api_url
  api_key    = var.pdns_api_key
}

variable "domain_name" {
  type = string
}
