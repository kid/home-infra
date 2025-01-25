data "sops_file" "truenas" {
  source_file = "${path.module}/../../../secrets/truenas.sops.yaml"
  input_type  = "yaml"
}

data "truenas_dataset" "parent_dataset" {
  dataset_id = var.parent_dataset_id
}
