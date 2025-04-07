provider "sops" {}

locals {
  ros_devices = {
    crs320 = {
      hosturl = "http://10.99.0.2"
    }
  }
}

provider "routeros" {
  alias    = "by_device"
  for_each = local.ros_devices

  # hosturl  = data.sops_file.routeros.data.routeros_endpoint
  hosturl  = each.value.hosturl
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}
