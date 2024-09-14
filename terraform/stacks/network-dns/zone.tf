locals {
  records = [
    { name = "pve0", ip = "10.0.10.10" },
    { name = "pve1", ip = "10.0.10.11" },
    { name = "ha", ip = "10.0.10.101" },
    { name = "plex", ip = "10.0.30.100" },
    { name = "prowlarr", ip = "10.0.30.110" },
    { name = "radarr", ip = "10.0.30.120" },
    { name = "sonarr", ip = "10.0.30.130" },
    { name = "animarr", ip = "10.0.30.140" },
    { name = "sabnzbd", ip = "10.0.30.150" },
  ]
}

resource "powerdns_zone" "local" {
  depends_on  = [module.pdns]
  name        = "${var.domain_name}."
  kind        = "Native"
  nameservers = ["ns1.${var.domain_name}."]
}

resource "powerdns_record" "ns" {
  zone    = powerdns_zone.local.name
  name    = "ns1.${var.domain_name}."
  type    = "A"
  ttl     = 300
  records = ["10.0.5.53"]
}

resource "powerdns_record" "local" {
  for_each = { for record in local.records : record.name => record }
  zone     = powerdns_zone.local.name
  type     = "A"
  ttl      = 300
  name     = "${each.value.name}.${powerdns_zone.local.name}"
  records  = [each.value.ip]
}
