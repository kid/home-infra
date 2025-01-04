resource "truenas_dataset" "democratic_csi" {
  pool   = "tank"
  name   = var.cluster_name
  parent = replace(data.truenas_dataset.parent_dataset.id, "/^${var.pool_name}\\//", "")
}

resource "truenas_dataset" "democratic_csi_volumes" {
  pool   = var.pool_name
  name   = "volumes"
  parent = replace(truenas_dataset.democratic_csi.id, "/^${var.pool_name}\\//", "")
}

resource "truenas_dataset" "democratic_csi_snapshots" {
  pool   = var.pool_name
  name   = "snapshots"
  parent = replace(truenas_dataset.democratic_csi.id, "/^${var.pool_name}\\//", "")
}
