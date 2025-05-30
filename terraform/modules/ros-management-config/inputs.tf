variable "hostname" {
  type = string
}

variable "bridge_name" {
  type = string
}

variable "mgmt_cidr_prefix" {
  type = string
}

variable "mgmt_cidr_bits" {
  type = number
}

variable "mgmt_hostnum" {
  type = number
}

variable "mgmt_vlan_id" {
  type = number
}

variable "oob_mgmt_port" {
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
