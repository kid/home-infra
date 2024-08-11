variable "flux_enable" {
  type    = bool
  default = true
}

module "flux" {
  count  = var.flux_enable ? 1 : 0
  source = "../../modules/flux-helm-bootstrap"

  depends_on = [
    data.talos_cluster_health.cluster,
    helm_release.cilium,
  ]

  cluster_name      = var.cluster_name
  github_org        = var.github_org
  github_repository = var.github_repository

  cluster_values = {
    cluster_name         = var.cluster_name
    cluster_domain       = "kidbox.net"
    proxmox_api_endpoint = "${var.proxmox_endpoint}/api2/json"
    proxmox_cluster_name = "pve"
    router_ip            = cidrhost(var.vlan_cidrs[var.vlan_id], 1)
    lb_cidr              = local.lb_cidr
  }

  cluster_secrets = merge(
    {
      cloudflare_account_id = var.cloudflare_account_id
      cloudflare_api_token  = var.cloudflare_api_token
      powerdns_api_url      = var.pdns_api_url
      powerdns_api_key      = var.pdns_api_key
      truenas_host          = var.truenas_host
      truenas_port          = var.truenas_port
      truenas_insecure      = var.truenas_insecure
      truenas_api_key       = var.truenas_api_key
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
