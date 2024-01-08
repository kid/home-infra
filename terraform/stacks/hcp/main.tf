locals {
  server_node_count   = 3
  client_node_count   = 2
  server_ip_addresses = [for _, idx in range(local.server_node_count) : "10.0.30.${50 + idx + 1}"]
  client_ip_addresses = [for _, idx in range(local.client_node_count) : "10.0.30.${60 + idx + 1}"]
}

module "hcp" {
  count = local.server_node_count

  source       = "../../modules/proxmox-vm"
  root_file_id = "local:iso/fedora-coreos-39.20231119.3.0-qemu.x86_64.img"
  node_name    = "pve1"
  vm_name      = "hcp-server-${count.index + 1}"
  ip_address   = local.server_ip_addresses[count.index]
  tags         = ["fcos", var.environment]

  cpu_cores        = 4
  memory_dedicated = 2048

  ignition_enabled  = true
  ignition_rendered = data.ct_config.server[count.index].rendered
}

module "client" {
  count = local.client_node_count

  source       = "../../modules/proxmox-vm"
  root_file_id = "local:iso/fedora-coreos-39.20231119.3.0-qemu.x86_64.img"
  node_name    = "pve1"
  vm_name      = "hcp-client-${count.index + 1}"
  ip_address   = local.client_ip_addresses[count.index]
  tags         = ["fcos", var.environment]

  ignition_enabled  = true
  ignition_rendered = data.ct_config.client[count.index].rendered

  cpu_cores        = 4
  memory_dedicated = 2048
}

locals {
  template_vars = {
    consul_version         = var.consul_version
    consul_checksum        = var.consul_checksum
    consul_servers         = local.server_ip_addresses
    consul_token           = var.consul_token
    consul_user            = "consul"
    consul_group           = "consul"
    nomad_version          = var.nomad_version
    nomad_checksum         = var.nomad_checksum
    podman_driver_version  = "0.5.1"
    podman_driver_checksum = "sha256-cef60b0dfd708ab2b5b1e517991cf933bce509a27b087c482e6993f3784dd572"
  }

  server_vars = [for _, idx in range(local.server_node_count) : merge(local.template_vars, {
    nomad_user  = "nomad"
    nomad_group = "nomad"
    hostname    = "hcp-server-${idx + 1}"
  })]

  client_vars = [for _, idx in range(local.client_node_count) : merge(local.template_vars, {
    nomad_user  = "root"
    nomad_group = "root"
    node_ip     = local.client_ip_addresses[idx]
    hostname    = "hcp-client-${idx + 1}"
  })]
}

data "ct_config" "server" {
  count        = local.server_node_count
  content      = templatefile("${path.module}/snippets/common.yaml", local.server_vars[count.index])
  strict       = true
  pretty_print = true

  snippets = [for path in [
    "./snippets/users.yaml",
    "./snippets/consul-common.yaml",
    "./snippets/consul-server.yaml",
    "./snippets/nomad-common.yaml",
    "./snippets/nomad-server.yaml",
  ] : templatefile(path, local.server_vars[count.index])]
}

data "ct_config" "client" {
  count        = local.client_node_count
  content      = templatefile("${path.module}/snippets/common.yaml", local.client_vars[count.index])
  strict       = true
  pretty_print = true

  snippets = [for path in [
    "./snippets/users.yaml",
    "./snippets/consul-common.yaml",
    "./snippets/consul-client.yaml",
    "./snippets/nomad-common.yaml",
    "./snippets/nomad-client.yaml",
    "./snippets/cni-plugins.yaml",
  ] : templatefile(path, local.client_vars[count.index])]
}
