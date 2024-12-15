wan_iface = "ether1"
mgmt_port = "ether5"

cidr = "10.1.0.0/16"

vlans = {
  adm = {
    vlan_id = 99
  }
  data = {
    vlan_id = 20
    mtu     = 9000
  }
  lan = {
    vlan_id = 100
  }
}
