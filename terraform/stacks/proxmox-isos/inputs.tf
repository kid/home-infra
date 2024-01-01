variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "flatcar_channel" {
  type    = string
  default = "beta"
}

variable "flatcar_release" {
  type    = string
  default = "3760.1.1"
}

variable "flatcar_arch" {
  type    = string
  default = "amd64-usr"
}
