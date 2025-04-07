variable "bridge_name" {
  type = string
}

variable "bridge_ports" {
  type = map(object({
    comment  = optional(string)
    vlan_ids = optional(list(number), [])
    pvid     = optional(number)
  }))
}

variable "ignore_interfaces" {
  type    = list(string)
  default = []
}
