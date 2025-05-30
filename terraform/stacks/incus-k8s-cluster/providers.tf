provider "sops" {}

data "sops_file" "routeros" {
  source_file = "${path.module}/../../../secrets/routeros.sops.yaml"
  input_type  = "yaml"
}

data "sops_file" "incus" {
  source_file = "${path.module}/../../../secrets/incus.sops.yaml"
  input_type  = "yaml"
}

provider "routeros" {
  hosturl  = data.sops_file.routeros.data.routeros_endpoint
  username = data.sops_file.routeros.data.routeros_username
  password = data.sops_file.routeros.data.routeros_password
  insecure = data.sops_file.routeros.data.routeros_insecure
}

provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true

  remote {
    default = true
    name    = data.sops_file.incus.data.incus_name
    scheme  = data.sops_file.incus.data.incus_scheme
    address = data.sops_file.incus.data.incus_address
    token   = data.sops_file.incus.data.incus_token
  }
}

provider "talos" {}
