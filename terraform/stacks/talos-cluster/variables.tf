variable "talos_version" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "vlan_id" {
  type    = number
  default = 40
}

variable "vlan_cidrs" {
  type = map(string)
  default = {
    40 = "10.0.40.0/24"
  }
}

variable "controlplane_ip_offset" {
  type    = number
  default = 10
}
