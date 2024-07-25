locals {
  blocky_intercept = true
}

module "blocky" {
  source = "../../modules/ros-container"

  name       = "blocky"
  image      = "ghcr.io/0xerr0r/blocky:v0.24"
  ip_address = "10.0.5.3/24"
  user_id    = 0

  env_vars = {
    BLOCKY_CONFIG_FILE = "/configs/config.yml"
  }

  mounts = {
    configs = {
      dst = "/configs"
    }
  }
}

resource "routeros_file" "blocky_config" {
  name = "usb1/containers/blocky/volumes/configs/config.yml"
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
      "tcp+udp:1.0.0.2",
    ],
    ports = {
      dns  = 53,
      tls  = 853,
      http = 8080,
      # https = 443,
    },
    conditional = {
      fallbackUpstream = true,
      mapping = {
        "kidibox.net" = trimsuffix(module.pdns.ip_address, "/24")
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
