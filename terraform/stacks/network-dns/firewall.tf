resource "routeros_interface_list" "dns_intercept" {
  name = "dns-intercept"
}

resource "routeros_interface_list_member" "dns_intercept" {
  for_each  = toset(var.dns_intercept_interfaces)
  list      = routeros_interface_list.dns_intercept.name
  interface = each.value
}

resource "routeros_ip_firewall_nat" "dstnat_dns_tcp" {
  depends_on = [module.coredns]

  chain = "dstnat"

  protocol          = "tcp"
  in_interface_list = routeros_interface_list.dns_intercept.name
  dst_port          = 53
  dst_address       = "!10.0.5.0/24"

  action       = "dst-nat"
  to_addresses = replace(module.coredns.ip_address, "//\\d+/", "")
  to_ports     = 53

  comment = "dns-intercept"
}

resource "routeros_ip_firewall_nat" "dstnat_dns_udp" {
  depends_on = [module.coredns]

  chain = "dstnat"

  protocol          = "udp"
  in_interface_list = routeros_interface_list.dns_intercept.name
  dst_port          = 53
  dst_address       = "!10.0.5.0/24"

  action       = "dst-nat"
  to_addresses = replace(module.coredns.ip_address, "//\\d+/", "")
  to_ports     = 53

  comment = "dns-intercept"
}

# resource "routeros_ip_firewall_nat" "redirect_dns_tcp" {
#   disabled = true
#
#   chain = "dstnat"
#
#   protocol    = "tcp"
#   dst_address = "10.0.100.1"
#   dst_port    = 5353
#
#   action       = "redirect"
#   to_addresses = replace(module.dns.ip_address, "//\\d+/", "")
#   to_ports     = 53
#
#   comment = "dns-redirect"
# }
#
# resource "routeros_ip_firewall_nat" "redirect_dns_udp" {
#   disabled = true
#
#   chain = "dstnat"
#
#   protocol    = "udp"
#   dst_address = "10.0.100.1"
#   dst_port    = 5353
#
#   action       = "redirect"
#   to_addresses = replace(module.dns.ip_address, "//\\d+/", "")
#   to_ports     = 53
#
#   comment = "dns-redirect"
# }

# TODO: add script to disable theses rules when dns is not responding
