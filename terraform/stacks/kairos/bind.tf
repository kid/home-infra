# TODO: https://github.com/mbentley/docker-bind9/tree/master

variable "bind_tsig_keys" {
  sensitive = true
  type = map(object({
    secret    = string,
    algorithm = string,
  }))
}

locals {
  bind_enabled = true
  bind_zones   = ["kidibox.net.internal"]
}

resource "routeros_interface_veth" "bind" {
  count   = local.bind_enabled ? 1 : 0
  name    = "veth-bind"
  address = "10.0.5.53/24"
  gateway = "10.0.5.1"
}

resource "routeros_interface_bridge_port" "bind" {
  count     = local.bind_enabled ? 1 : 0
  bridge    = "bridge1"
  interface = routeros_interface_veth.bind[0].name
  pvid      = 5
}

resource "routeros_container" "bind" {
  count = local.bind_enabled ? 1 : 0

  depends_on = [
    routeros_file.bind_config,
    routeros_file.bind_zones,
  ]

  remote_image  = "ghcr.io/kid/home-infra/bind:latest"
  interface     = routeros_interface_veth.bind[0].name
  logging       = true
  start_on_boot = true
  root_dir      = "usb1/containers/bind/root"
  envlist       = routeros_container_envs.bind_tz.name
  # user          = "0"
  mounts = [
    routeros_container_mounts.bind_configs[0].name,
  ]

  cmd = "named -g -u named -4"

  lifecycle {
    replace_triggered_by = [routeros_file.bind_config, routeros_container_mounts.bind_configs, routeros_container_envs.bind_tz]
  }
}

resource "routeros_container_mounts" "bind_configs" {
  depends_on = [routeros_file.bind_config]

  count = local.bind_enabled ? 1 : 0
  name  = "bind-configs"
  src   = "/usb1/containers/bind/volumes/configs"
  dst   = "/etc/bind"
}

resource "routeros_container_envs" "bind_tz" {
  name  = "bind_envs"
  key   = "TZ"
  value = "Europe/Brussels"
}

resource "routeros_file" "bind_config" {
  name = "usb1/containers/bind/volumes/configs/named.conf"
  contents = templatefile("${path.module}/files/named.conf.tpl", {
    tsig_keys = var.bind_tsig_keys,
    zones     = local.bind_zones
  })
}

resource "time_static" "zone_serial" {
  for_each = toset(local.bind_zones)

  triggers = {
    content = sha256(templatefile("${path.module}/files/${each.key}.zone", { serial = 0 }))
  }
}

resource "routeros_file" "bind_zones" {
  for_each = toset(local.bind_zones)

  name = "usb1/containers/bind/volumes/configs/db.${each.key}"
  contents = templatefile("${path.module}/files/${each.key}.zone", {
    serial = resource.time_static.zone_serial[each.key].unix
  })
}
