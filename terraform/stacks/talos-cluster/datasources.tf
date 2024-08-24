data "sops_file" "cluster" {
  source_file = "${path.module}/../../../secrets/${var.cluster_name}.sops.yaml"
}
