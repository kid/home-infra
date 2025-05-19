locals {
  enabled_services = [
    "ssh",
    "www",
    # TODO: setup TLS certs
    # "www-ssl",
    "winbox"
  ]
}

data "routeros_ip_services" "self" {}

resource "routeros_ip_service" "self" {
  depends_on = [
    routeros_ip_address.oob,
    routeros_ip_address.mgmt
  ]

  for_each = { for _, v in data.routeros_ip_services.self.services : v.name => v }
  numbers  = each.key
  port     = each.value.port
  disabled = !contains(local.enabled_services, each.key)
  address = contains(local.enabled_services, each.key) ? join(",", [
    local.oob_mgmt_cidr,
    local.mgmt_cidr,
  ]) : null
}

resource "routeros_ip_ssh_server" "self" {
  always_allow_password_login = false
  strong_crypto               = true
  forwarding_enabled          = "remote"
  host_key_type               = "ed25519"
}
