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

variable "routeros_endpoint" {
  type = string
}

variable "routeros_username" {
  type      = string
  sensitive = true
}

variable "routeros_password" {
  type      = string
  sensitive = true
}

variable "routeros_insecure" {
  type    = bool
  default = false
}

variable "cloudflare_account_id" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "pdns_api_url" {
  type = string
}

variable "pdns_api_key" {
  type      = string
  sensitive = true
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
variable "github_org" {
  type    = string
  default = "kid"
}

variable "github_repository" {
  type    = string
  default = "home-infra"
}

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


variable "bootstrap" {
  type    = bool
  default = false
}

variable "gcloud_api_key" {
  type      = string
  sensitive = true
}
