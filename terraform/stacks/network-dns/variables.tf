variable "domain_name" {
  type = string
}

variable "dns_intercept_interfaces" {
  type    = list(string)
  default = []
}
