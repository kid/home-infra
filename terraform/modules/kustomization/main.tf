data "kustomization_overlay" "self" {
  components = var.components
  resources  = var.resources

  kustomize_options {
    load_restrictor = "none"
  }
}

resource "kustomization_resource" "p0" {
  for_each = data.kustomization_overlay.self.ids_prio[0]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.self.manifests[each.value])
    : data.kustomization_overlay.self.manifests[each.value]
  )
}

resource "kustomization_resource" "p1" {
  for_each = data.kustomization_overlay.self.ids_prio[1]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.self.manifests[each.value])
    : data.kustomization_overlay.self.manifests[each.value]
  )
  wait = true

  depends_on = [kustomization_resource.p0]
}

resource "kustomization_resource" "p2" {
  for_each = data.kustomization_overlay.self.ids_prio[2]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.self.manifests[each.value])
    : data.kustomization_overlay.self.manifests[each.value]
  )

  depends_on = [kustomization_resource.p1]
}
