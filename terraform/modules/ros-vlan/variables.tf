variable "bridge_name" {
  type    = string
  default = "bridge1"
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
