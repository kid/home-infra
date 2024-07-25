variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "vlan_id" {
  default = 5
}

variable "user_id" {
  type    = number
  default = null
}

variable "ip_address" {
  type = string
}

variable "default_env_vars" {
  type = map(string)
  default = {
    "TZ" = "Europe/Brussels"
  }
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "mounts" {
  type = map(object({
    src = optional(string)
    dst = string
  }))
  default = {}
}
