provider "sops" {}

provider "routeros" {
  hosturl  = data.sops_file.routeros.data.routeros_endpoint
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}

provider "powerdns" {
  server_url = data.sops_file.powerdns.data.pdns_api_url
  api_key    = data.sops_file.powerdns.data.pdns_api_key
}
