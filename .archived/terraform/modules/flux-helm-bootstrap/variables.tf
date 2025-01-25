variable "cluster_name" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "cluster_values" {
  type    = map(string)
  default = {}
}

variable "cluster_secrets" {
  type      = map(string)
  sensitive = true
  default   = {}
}

variable "extra_config_maps" {
  type    = map(map(string))
  default = {}
}
