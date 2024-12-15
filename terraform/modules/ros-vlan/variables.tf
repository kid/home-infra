variable "bridge_name" {
  type = string
}

variable "vlan_id" {
  type = number
}

variable "vlan_name" {
  type = string
}

variable "vlan_cidr" {
  type = string
}

variable "vlan_mtu" {
  type    = number
  default = 1500
}

variable "tagged_ifces" {
  type    = list(string)
  default = []
}

variable "dhcp_lease_time" {
  type    = string
  default = "1d"
}

variable "dhcp_dns_servers" {
  type    = list(string)
  default = []
}

variable "dhcp_domain" {
  type    = string
  default = null
}
