locals {
  env_vars = merge(var.default_env_vars, var.env_vars)
}

resource "routeros_container_envs" "self" {
  for_each = local.env_vars
  name     = var.name
  key      = each.key
  value    = each.value
}

resource "routeros_interface_veth" "self" {
  name    = "veth-${var.name}"
  address = var.ip_address
  gateway = cidrhost(var.ip_address, 1)
}

resource "routeros_interface_bridge_port" "self" {
  bridge    = "bridge1"
  interface = routeros_interface_veth.self.name
  pvid      = var.vlan_id
}

resource "routeros_container" "self" {
  depends_on = [
    routeros_interface_bridge_port.self,
  ]

  remote_image  = var.image
  interface     = routeros_interface_veth.self.name
  user          = var.user_id
  logging       = true
  start_on_boot = true
  root_dir      = "usb1/containers/${var.name}/root"
  envlist       = length(keys(local.env_vars)) > 0 ? var.name : null
  mounts        = [for k, _ in var.mounts : routeros_container_mounts.self[k].name]
}

resource "routeros_container_mounts" "self" {
  for_each = var.mounts
  name     = "${var.name}-${each.key}"
  # src      = length(each.value.src) > 0 ? "/${trim(each.value.src, "/")}" : "/usb1/containers/${var.name}/volumes/${each.key}"
  src = "/${trim(coalesce(each.value.src, "usb1/containers/${var.name}/volumes/${each.key}"), "/")}"
  dst = each.value.dst
}
