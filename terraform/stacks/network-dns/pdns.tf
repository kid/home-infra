module "pdns" {
  source = "../../modules/ros-container"

  name       = "pdns"
  image      = "kid/home-infra/powerdns:9aac103b"
  ip_address = "10.0.5.53/24"

  env_vars = {
    API_KEY            = var.pdns_api_key_hash
    ENABLE_LUA_RECORDS = "shared"
  }

  mounts = {
    data = {
      dst = "/var/lib/powerdns"
    }
  }
}

# resource "routeros_interface_veth" "pdns" {
#   count   = local.pdns_enabled ? 1 : 0
#   name    = "veth-pdns"
#   address = "10.0.5.30/24"
#   gateway = "10.0.5.1"
# }
#
# resource "routeros_interface_bridge_port" "pdns" {
#   count     = local.pdns_enabled ? 1 : 0
#   bridge    = "bridge1"
#   interface = routeros_interface_veth.pdns[0].name
#   pvid      = 5
# }
#
# resource "routeros_container" "pdns" {
#   depends_on = [
#     routeros_interface_bridge_port.pdns,
#     routeros_container_envs.pdns,
#   ]
#
#   count         = local.pdns_enabled ? 1 : 0
#   remote_image  = "kid/home-infra/powerdns:latest"
#   interface     = routeros_interface_veth.pdns[0].name
#   logging       = true
#   start_on_boot = true
#   root_dir      = "usb1/containers/pdns/root"
#   envlist       = local.pdns_env_name
#   mounts = [
#     routeros_container_mounts.pdns_data[0].name,
#   ]
# }
#
# resource "routeros_container_mounts" "pdns_data" {
#   count = local.pdns_enabled ? 1 : 0
#   name  = "pdns-data"
#   src   = "/usb1/containers/pdns/volumes/data"
#   dst   = "/var/lib/powerdns"
# }
#
# resource "routeros_container_envs" "pdns" {
#   for_each = local.pdns_envs
#   name     = local.pdns_env_name
#   key      = each.key
#   value    = each.value
# }
