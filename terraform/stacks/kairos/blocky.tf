locals {
  blocky_enabled   = true
  blocky_intercept = true
}

resource "routeros_interface_veth" "blocky" {
  count   = local.blocky_enabled ? 1 : 0
  name    = "veth-blocky"
  address = "10.0.5.3/24"
  gateway = "10.0.5.1"
}

resource "routeros_interface_bridge_port" "blocky" {
  count     = local.blocky_enabled ? 1 : 0
  bridge    = "bridge1"
  interface = routeros_interface_veth.blocky[0].name
  pvid      = 5
}

resource "routeros_container" "blocky" {
  count         = local.blocky_enabled ? 1 : 0
  remote_image  = "ghcr.io/0xerr0r/blocky:latest"
  interface     = routeros_interface_veth.blocky[0].name
  logging       = true
  start_on_boot = true
  root_dir      = "usb1/containers/blocky/root"
  mounts        = [routeros_container_mounts.blocky_configs[0].name]
  envlist       = routeros_container_envs.blocky_config.name
  user          = "0"

  lifecycle {
    replace_triggered_by = [routeros_file.blocky_config]
  }
}

resource "routeros_container_mounts" "blocky_configs" {
  count      = local.blocky_enabled ? 1 : 0
  depends_on = [routeros_file.blocky_config]
  name       = "blocky-configs"
  src        = "/usb1/containers/blocky/volumes/configs"
  dst        = "/configs"
}

resource "routeros_container_envs" "blocky_tz" {
  name  = "blocky_envs"
  key   = "TZ"
  value = "Europe/Brussels"
}

resource "routeros_container_envs" "blocky_config" {
  name  = "blocky_envs"
  key   = "BLOCKY_CONFIG_FILE"
  value = "/configs/config.yml"
}

resource "routeros_file" "blocky_config" {
  count = local.blocky_enabled ? 1 : 0
  name  = "usb1/containers/blocky/volumes/configs/config.yml"
  contents = yamlencode({
    upstreams = {
      groups = {
        default = [
          "https://security.cloudflare-dns.com/dns-query",
          "https://dns.quad9.net/dns-query"
        ],
      }
    },
    bootstrapDns = [
      "tcp+udp:1.1.1.2",
      "tcp+udp:1.1.1.1",
    ],
    ports = {
      dns  = 53,
      tls  = 853,
      http = 8080,
      # https = 443,
    },
    conditional = {
      mapping = {
        "kidibox.net" = "10.0.5.53",
      },
    },
    caching = {
      prefetching = true,
    },
    prometheus = {
      enable = true,
    },
  })
}

resource "routeros_ip_firewall_nat" "dstnat_dns_tcp" {
  disabled = !local.blocky_intercept

  chain = "dstnat"

  protocol     = "tcp"
  in_interface = "lan"
  dst_port     = 53

  action       = "dst-nat"
  to_addresses = replace(routeros_interface_veth.blocky[0].address, "//\\d+/", "")
  to_ports     = 53

  comment = "blocky-redirect"
}

resource "routeros_ip_firewall_nat" "dstnat_dns_udp" {
  disabled = !local.blocky_intercept

  chain = "dstnat"

  protocol     = "udp"
  in_interface = "lan"
  dst_port     = 53

  action       = "dst-nat"
  to_addresses = replace(routeros_interface_veth.blocky[0].address, "//\\d+/", "")
  to_ports     = 53
  # in_interface_list = "LAN"

  comment = "blocky-redirect"
}

resource "routeros_ip_firewall_nat" "redirect_dns_tcp" {
  disabled = true

  chain = "dstnat"

  protocol    = "tcp"
  dst_address = "10.0.100.1"
  dst_port    = 5353

  action       = "redirect"
  to_addresses = replace(routeros_interface_veth.blocky[0].address, "//\\d+/", "")
  to_ports     = 53

  comment = "blocky-redirect"
}

resource "routeros_ip_firewall_nat" "redirect_dns_udp" {
  disabled = true

  chain = "dstnat"

  protocol    = "udp"
  dst_address = "10.0.100.1"
  dst_port    = 5353

  action       = "redirect"
  to_addresses = replace(routeros_interface_veth.blocky[0].address, "//\\d+/", "")
  to_ports     = 53

  comment = "blocky-redirect"
}

# TODO: add script to disable theses rules when blocky is not responding
