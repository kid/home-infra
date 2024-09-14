module "pdns" {
  source = "../../modules/ros-container"

  name       = "pdns"
  file       = "pdns.tar"
  ip_address = "10.0.5.53/24"

  env_vars = {
    API_KEY            = data.sops_file.powerdns.data.pdns_api_key_hash
    ENABLE_LUA_RECORDS = "shared"
  }

  mounts = {
    data = {
      dst = "/var/lib/powerdns"
    }
  }
}
