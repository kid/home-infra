variable "environment" {
  type = string
}

variable "consul_token" {
  type      = string
  sensitive = true
}

variable "consul_version" {
  type    = string
  default = "1.17.1"
}

variable "consul_checksum" {
  type    = string
  default = "sha256-388889321d6aaf389ee87acc247ea9885e684a1581c8ebfbeab7348abd7c0214"
}

variable "nomad_version" {
  type    = string
  default = "1.7.2"
}

variable "nomad_checksum" {
  type    = string
  default = "sha256-5264b4f4b9a0bf8f086544f15e6a6377c856e5556bf44337c958f5356d251331"
}

