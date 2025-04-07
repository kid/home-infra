module "crs320_bridge" {
  providers = {
    routeros = routeros.by_device["crs320"]
  }

  source = "../../modules/ros-bridge"

  bridge_name = "bridge1"
  bridge_ports = {
    sfp-sfpplus1 = {
      vlan_ids = [99, 10, 30, 100, 101]
    }
    ether1 = {
      comment  = "office-east"
      pvid     = 100
      vlan_ids = [99]
    }
    ether3 = {
      comment = "office-west"
      pvid    = 100
    }
    ether7 = {
      comment  = "capax1"
      vlan_ids = [99, 100, 101]
    }
    ether9 = {
      comment  = "capax0"
      vlan_ids = [99, 100, 101]
    }
    ether10 = {
      comment = "doorbell"
      pvid    = 101
    }
    ether11 = {
      comment = "petdoor"
      pvid    = 101
    }
    ether13 = {
      comment = "pve0"
      pvid    = 10
    }
    ether14 = {
      comment = "pve0-ipmi"
      pvid    = 99
    }
    ether15 = {
      comment = "pve1-ipmi"
      pvid    = 99
    }
    ether16 = {
      commment = "mgmt"
      pvid     = 99
    }
  }

  ignore_interfaces = ["ether17"]
}

module "crs320_management_config" {
  providers = {
    routeros = routeros.by_device["crs320"]
  }

  source = "../../modules/ros-management-config"

  bridge_name      = module.crs320_bridge.bridge_name
  mgmt_vlan_id     = 99
  oob_mgmt_address = "192.168.88.1/24"
  oob_mgmt_port    = "ether17"
}

output "debug" {
  value = var.debug ? module.crs320_bridge.debug : null
}
