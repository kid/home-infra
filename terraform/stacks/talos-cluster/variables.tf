variable "talos_version" {
  type = string
}

variable "talos_schematic_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vlan_id" {
  type    = number
  default = 30
}

variable "vlan_cidrs" {
  type = map(string)
  default = {
    30 = "10.0.30.0/24"
  }
}

variable "controlplane_ip_offset" {
  type    = number
  default = 80
}

variable "truenas_host" {
  type = string
}

variable "truenas_port" {
  type = number
}

variable "truenas_insecure" {
  type    = bool
  default = true
}

variable "truenas_api_key" {
  type      = string
  sensitive = true
}
