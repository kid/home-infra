locals {
  dhcp_options = {
    # option17 = {
    #   code  = 17
    #   value = "'http://10.0.5.2/boot.ipxe'"
    # }
    server-name = {
      code  = 66
      value = "'10.0.30.1'"
    }
    boot-file-name-bios = {
      code  = 67
      value = "'ipxe.pxe'"
    }
    boot-file-name-efi = {
      code  = 67
      value = "'ipxe.efi'"
    }
    boot-file-name-ipxe = {
      code  = 67
      value = "'http://10.0.5.2/boot.ipxe'"
    }
  }
}

resource "routeros_ip_dhcp_server_option" "pxe" {
  for_each = local.dhcp_options
  name     = each.key
  code     = each.value.code
  value    = each.value.value
}

resource "routeros_ip_dhcp_server_option_set" "bios" {
  name = "bios"
  options = join(",", [
    routeros_ip_dhcp_server_option.pxe["server-name"].name,
    # routeros_ip_dhcp_server_option.pxe["option17"].name,
    routeros_ip_dhcp_server_option.pxe["boot-file-name-bios"].name,
  ])
}

resource "routeros_ip_dhcp_server_option_set" "efi" {
  name = "efi"
  options = join(",", [
    routeros_ip_dhcp_server_option.pxe["server-name"].name,
    # routeros_ip_dhcp_server_option.pxe["option17"].name,
    routeros_ip_dhcp_server_option.pxe["boot-file-name-efi"].name,
  ])
}

resource "routeros_ip_dhcp_server_option_set" "ipxe" {
  name = "ipxe"
  options = join(",", [
    routeros_ip_dhcp_server_option.pxe["server-name"].name,
    # routeros_ip_dhcp_server_option.pxe["option17"].name,
    routeros_ip_dhcp_server_option.pxe["boot-file-name-ipxe"].name,
  ])
}

resource "routeros_ip_dhcp_client" "wan" {
  interface         = local.wan_port
  add_default_route = "yes"
  use_peer_dns      = false
  use_peer_ntp      = false
}

resource "routeros_ip_address" "vlans" {
  for_each  = local.vlan_cidrs
  interface = routeros_interface_vlan.vlan[each.key].name
  network   = split("/", local.vlan_cidrs[each.key])[0]
  address   = "${cidrhost(each.value, 1)}/${split("/", each.value)[1]}"
}

resource "routeros_ip_pool" "vlans" {
  for_each = local.vlan_cidrs
  name     = each.key
  ranges   = ["${cidrhost(each.value, 100)}-${cidrhost(each.value, 254)}"]
}

resource "routeros_ip_dhcp_server" "vlans" {
  depends_on   = [routeros_interface_vlan.vlan]
  for_each     = local.vlans
  name         = each.key
  interface    = each.key
  lease_time   = "1d"
  address_pool = routeros_ip_pool.vlans[each.key].name
}

# locals {
#   vlan_cidr_to_dhcp_option_set = {
#     "10.0.30.0/24" = "pxe-efi"
#   }
# }

resource "routeros_ip_dhcp_server_network" "vlans" {
  depends_on = [
    routeros_ip_dhcp_server_option_set.bios,
    routeros_ip_dhcp_server_option_set.efi,
  ]
  for_each   = local.vlan_cidrs
  address    = each.value
  gateway    = cidrhost(each.value, 1)
  dns_server = [cidrhost(each.value, 1)]
  domain     = "${each.key}.${local.tld}"

  # TODO: find a better way
  # dhcp_option_set = lookup(local.vlan_cidr_to_dhcp_option_set, each.value, null)
}

resource "routeros_dhcp_server_lease" "static_hosts" {
  # lifecycle {
  #   # avoids conflicts when making changes
  #   create_before_destroy = false
  # }

  for_each    = { for k, v in local.hosts : k => v }
  comment     = each.key
  address     = each.value.ip
  mac_address = upper(each.value.mac)
  server      = each.value.dhcp_server
}
