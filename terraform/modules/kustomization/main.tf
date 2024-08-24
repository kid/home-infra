# NOTE: taken from https://github.com/kbst/terraform-provider-kustomization/issues/251

data "kustomization_overlay" "self" {
  components = var.components
  resources  = var.resources

  kustomize_options {
    load_restrictor = "none"
  }
}

locals {
  decoded_manifests = {
    for k in data.kustomization_overlay.self.ids : k => jsondecode(data.kustomization_overlay.self.manifests[k])
  }

  # The kubernetes_manifest resource does not support overriding status but
  # the kustomization_build generates a status block that needs to be removed.
  #
  #
  # The metadata.creationTimestamp causes a perma-drift if it is not removed.
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1378
  #
  # Neither:
  #
  # computed_fields = [
  #   "metadata.annotations",
  #   "metadata.creationTimestamp",
  #   "metadata.labels",
  # ]
  #
  # Nor:
  #
  # lifecycle {
  #   ignore_changes = [
  #     object.metadata.creationTimestamp,
  #   ]
  # }
  #
  # Works to address that issue.
  filtered_manifests = {
    for k, v in local.decoded_manifests : k => merge(
      { for kk, vv in v : kk => vv if kk != "status" && kk != "metadata" },
      { for kk, vv in v : kk => (
        { for kkk, vvv in vv : kkk => vvv if kkk != "creationTimestamp" }
      ) if kk == "metadata" },
    )
  }
}

# first loop through resources in ids_prio[0]
resource "kubernetes_manifest" "p0" {
  for_each = data.kustomization_overlay.self.ids_prio[0]

  manifest = (
    local.filtered_manifests[each.value].kind == "Secret"
    ? sensitive(local.filtered_manifests[each.value])
    : local.filtered_manifests[each.value]
  )

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
    "spec.template.metadata.annotations",
    "spec.template.metadata.labels",
  ]
}


# then loop through resources in ids_prio[1]
# and set an explicit depends_on on kustomization_resource.p0
# wait for any Deployment, StatefulSet or DaemonSet to become ready
resource "kubernetes_manifest" "p1" {
  for_each = data.kustomization_overlay.self.ids_prio[1]

  manifest = (
    local.filtered_manifests[each.value].kind == "Secret"
    ? sensitive(local.filtered_manifests[each.value])
    : local.filtered_manifests[each.value]
  )

  dynamic "wait" {
    for_each = toset(
      local.filtered_manifests[each.value].kind == "Deployment"
      || local.filtered_manifests[each.value].kind == "StatefulSet"
      || local.filtered_manifests[each.value].kind == "DaemonSet"
    ? ["true"] : [])
    content {
      rollout = true
    }
  }

  # splat syntax fails for: "spec.template.spec.containers[*].resources.requests.cpu",
  computed_fields = flatten(concat([
    "metadata.annotations",
    "metadata.labels",
    "spec.template.metadata.annotations",
    "spec.template.metadata.labels",
    ],
    (can(local.filtered_manifests[each.value].spec.template.spec.containers)
      ? [
        for i, v in local.filtered_manifests[each.value].spec.template.spec.containers :
        "spec.template.spec.containers[${i}].resources.requests[\"cpu\"]"
      ]
      : []
    )
  ))

  field_manager {
    force_conflicts = true
  }

  depends_on = [kubernetes_manifest.p0]
}

# finally, loop through resources in ids_prio[2]
# and set an explicit depends_on on kubernetes_manifest.p1
resource "kubernetes_manifest" "p2" {
  for_each = data.kustomization_overlay.self.ids_prio[2]

  manifest = (
    local.filtered_manifests[each.value].kind == "Secret"
    ? sensitive(local.filtered_manifests[each.value])
    : local.filtered_manifests[each.value]
  )

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
    "spec.template.metadata.annotations",
    "spec.template.metadata.labels",
  ]

  depends_on = [kubernetes_manifest.p1]
}
