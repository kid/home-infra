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
    sfp-sfpplus3 = {
      comment  = "pve0"
      vlan_ids = [30, 100, 101]
    }
    sfp-sfpplus4 = {
      comment = "pve1"
      pvid    = 10
      # FIXME: tag 10 is only there for home-assistant
      vlan_ids = [30, 100, 101]
    }
    ether1 = {
      comment  = "office-east"
      pvid     = 100
      vlan_ids = [99]
    }
    ether2 = {
      commment = "rb5009"
      pvid     = 99
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
      comment = "pve1"
      pvid    = 99
      # pvid = 10
      # # FIXME: tag 10 is only there for home-assistant
      # vlan_ids = [30, 100, 101]
    }
    ether16 = {
      comment = "pve1-ipmi"
      pvid    = 99
    }
  }

  ignore_interfaces = ["ether17"]
}

module "crs320_management_config" {
  providers = {
    routeros = routeros.by_device["crs320"]
  }

  source = "../../modules/ros-management-config"

  hostname    = "crs320"
  bridge_name = module.crs320_bridge.bridge_name

  mgmt_cidr_prefix = "10.99.0.0"
  mgmt_cidr_bits   = 16
  mgmt_hostnum     = 2
  mgmt_vlan_id     = 99

  oob_mgmt_port = "ether17"
}

output "debug" {
  value = var.debug ? {
    bridge = module.crs320_bridge.debug
    mgmt   = module.crs320_management_config.debug
  } : null
}
