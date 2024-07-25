resource "routeros_ip_firewall_nat" "dstnat_dns_tcp" {
  depends_on = [module.blocky]
  disabled   = !local.blocky_intercept

  chain = "dstnat"

  protocol     = "tcp"
  in_interface = "lan"
  dst_port     = 53

  action       = "dst-nat"
  to_addresses = replace(module.blocky.ip_address, "//\\d+/", "")
  to_ports     = 53

  comment = "blocky-redirect"
}

resource "routeros_ip_firewall_nat" "dstnat_dns_udp" {
  depends_on = [module.blocky]
  disabled   = !local.blocky_intercept

  chain = "dstnat"

  protocol     = "udp"
  in_interface = "lan"
  dst_port     = 53

  action       = "dst-nat"
  to_addresses = replace(module.blocky.ip_address, "//\\d+/", "")
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
  to_addresses = replace(module.blocky.ip_address, "//\\d+/", "")
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
  to_addresses = replace(module.blocky.ip_address, "//\\d+/", "")
  to_ports     = 53

  comment = "blocky-redirect"
}

# TODO: add script to disable theses rules when blocky is not responding
