variable "name" {
  type = string
}

variable "image" {
  type    = string
  default = null
}

variable "file" {
  type    = string
  default = null
}

variable "vlan_id" {
  type    = number
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

variable "cmd" {
  type    = string
  default = null
}
