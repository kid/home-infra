provider "sops" {}

provider "truenas" {
  base_url = "http://${data.sops_file.truenas.data.truenas_host}/api/v2.0"
  api_key  = data.sops_file.truenas.data.truenas_api_key
}
