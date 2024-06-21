resource "routeros_interface_veth" "dnsdist" {
  name    = "veth-dnsdist"
  address = "10.0.5.3/24"
  gateway = "10.0.5.1"
}

resource "routeros_interface_bridge_port" "dnsdist" {
  bridge    = "bridge1"
  interface = routeros_interface_veth.dnsdist.name
  pvid      = 5
}

resource "routeros_container" "dnsdist" {
  remote_image  = "kid/home-infra/dnsdist:latest"
  interface     = routeros_interface_veth.dnsdist.name
  logging       = true
  start_on_boot = true
  root_dir      = "usb1/containers/dnsdist/root"
}
