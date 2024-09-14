variable "flux_enable" {
  type    = bool
  default = true
}

# module "flux_kustomize" {
#   source = "../../modules/kustomization"
#
#   resources = [
#     "${path.module}/../../../clusters/${var.cluster_name}/flux"
#   ]
# }

module "flux" {
  count = var.flux_enable ? 1 : 0
  # source = "../../modules/flux-helm-bootstrap"
  source = "../../modules/flux-kustomized"

  # depends_on = [
  #   data.talos_cluster_health.cluster,
  #   helm_release.cilium,
  # ]

  cluster_name = var.cluster_name
  # github_org        = var.github_org
  # github_repository = var.github_repository

  sops_age = data.sops_file.cluster.data["age.ageKey"]

  cluster_values = {
    cluster_name         = var.cluster_name
    cluster_domain       = "kidbox.net"
    proxmox_api_endpoint = "${data.sops_file.proxmox.data.proxmox_endpoint}/api2/json"
    proxmox_cluster_name = "pve"
    router_ip            = cidrhost(var.vlan_cidrs[var.vlan_id], 1)
    lb_cidr              = local.lb_cidr
  }

  cluster_secrets = merge(
    {
      cloudflare_account_id = data.sops_file.cloudflare.data.cloudflare_account_id
      cloudflare_api_token  = data.sops_file.cloudflare.data.cloudflare_api_token
      powerdns_api_url      = data.sops_file.powerdns.data.pdns_api_url
      powerdns_api_key      = data.sops_file.powerdns.data.pdns_api_key
      truenas_host          = data.sops_file.truenas.data.truenas_host
      truenas_port          = data.sops_file.truenas.data.truenas_port
      truenas_insecure      = data.sops_file.truenas.data.truenas_insecure
      truenas_api_key       = data.sops_file.truenas.data.truenas_api_key
      gcloud_rw_api_key     = data.sops_file.grafana.data.gcloud_api_key
    },
    var.proxmox_ccm_enable ? {
      proxmox_ccm_token_id     = proxmox_virtual_environment_user_token.ccm[0].id
      proxmox_ccm_token_secret = trimprefix(proxmox_virtual_environment_user_token.ccm[0].value, "${proxmox_virtual_environment_user_token.ccm[0].id}=")
    } : {},
    var.proxmox_csi_enable ? {
      proxmox_csi_token_id     = proxmox_virtual_environment_user_token.csi[0].id
      proxmox_csi_token_secret = trimprefix(proxmox_virtual_environment_user_token.csi[0].value, "${proxmox_virtual_environment_user_token.csi[0].id}=")
    } : {}
  )

  extra_config_maps = merge(
    var.cilium_enable ? {
      "cilium-values" = {
        "values.yaml" = yamlencode(local.cilium_values)
      }
    } : null
  )
}
