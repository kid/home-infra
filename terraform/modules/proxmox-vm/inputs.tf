variable "tags" {
  type    = list(string)
  default = []
}

variable "node_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "root_file_id" {
  type = string
}

variable "ip_address" {
  type = string
}

variable "cpu_cores" {
  type    = number
  default = 4
}

variable "memory_dedicated" {
  type    = number
  default = 1024
}

variable "memory_floating" {
  type    = number
  default = 512
}

variable "data_disks" {
  type = list(object({
    size = number
  }))
  default = []
}

variable "ignition_enabled" {
  type    = bool
  default = false
}

variable "ignition_rendered" {
  type    = string
  default = ""
}


