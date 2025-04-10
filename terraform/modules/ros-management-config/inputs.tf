variable "bridge_name" {
  type = string
}

variable "oob_mgmt_interface" {
  type = string
}

variable "oob_mgmt_cidr_prefix" {
  type    = string
  default = "192.168.88.0"
}

variable "oob_mgmt_cidr_bits" {
  type    = number
  default = 24
}

variable "mgmt_vlan_id" {
  type = number
}
