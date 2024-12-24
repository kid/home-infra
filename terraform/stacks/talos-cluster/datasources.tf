data "sops_file" "proxmox" {
  source_file = "${path.module}/../../../secrets/proxmox.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "routeros" {
  source_file = "${path.module}/../../../secrets/routeros.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "truenas" {
  source_file = "${path.module}/../../../secrets/truenas.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "cloudflare" {
  source_file = "${path.module}/../../../secrets/cloudflare.sops.yaml"
  input_type  = "yaml"
}

# data "sops_file" "grafana" {
#   source_file = "${path.module}/../../../secrets/grafana.sops.yaml"
#   input_type  = "yaml"
# }
