terraform {
  required_version = ">= 1.8.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.85.3"
    }
  }
}

locals {
  cidr = "${var.cidr_prefix}/${var.cidr_bits}"
}

variable "interface" {
  type = string
}

variable "cidr_prefix" {
  type = string
}

variable "cidr_bits" {
  type    = number
  default = 24
}

variable "dhcp_start_ip" {
  type    = number
  default = 200
}

variable "dhcp_end_ip" {
  type    = number
  default = 254
}

variable "dhcp_lease_time" {
  type    = string
  default = "1d"
}

resource "routeros_ip_pool" "self" {
  name   = var.interface
  ranges = ["${cidrhost(local.cidr, var.dhcp_start_ip)}-${cidrhost(local.cidr, var.dhcp_end_ip)}"]
}

resource "routeros_ip_dhcp_server" "self" {
  name         = var.interface
  interface    = var.interface
  lease_time   = var.dhcp_lease_time
  address_pool = routeros_ip_pool.self.name
}

resource "routeros_ip_dhcp_server_network" "self" {
  address = local.cidr
}
