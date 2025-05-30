resource "macaddress" "instance1" {
  prefix = [0, 22, 62]
}

resource "routeros_ip_dhcp_server_lease" "instance1" {
  address     = "10.0.30.10"
  mac_address = macaddress.instance1.address
}

resource "incus_instance" "instance1" {
  name  = "instance1"
  image = incus_image.talos.fingerprint
  type  = "virtual-machine"

  profiles = ["kube"]

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "kube"
      hwaddr  = macaddress.instance1.address
    }
  }

  config = {
    "security.secureboot" = false
    "boot.autostart"      = true
    "limits.cpu"          = 2
    "limits.memory"       = "2GiB"
  }

  lifecycle {
    replace_triggered_by = [incus_image.talos]
  }
}
