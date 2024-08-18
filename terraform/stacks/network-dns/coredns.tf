module "coredns" {
  source = "../../modules/ros-container"

  name       = "coredns"
  file       = "coredns.tar"
  ip_address = "10.0.5.3/24"

  env_vars = {
    LOCAL_ZONE_NAME    = "kidibox.net."
    LOCAL_UPSTREAM_IP  = "10.0.5.53"
    REMOTE_UPSTREAM_IP = "1.1.1.2"
  }

  cmd = "-conf /configs/Corefile"

  mounts = {
    configs = {
      dst = "/configs"
    }
  }
}

resource "routeros_file" "coredns_config" {
  name     = "usb1/containers/coredns/volumes/configs/Corefile"
  contents = file("${path.module}/files/Corefile")
}
