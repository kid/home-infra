locals {
  talos_version = "v1.10.2"
}

module "talos_image" {
  source = "../../modules/talos-image"

  talos_version = local.talos_version
}

resource "incus_image" "talos" {
  source_file = {
    data_path = module.talos_image.archive_path
  }

  depends_on = [module.talos_image]

  # lifecycle {
  #   replace_triggered_by = [module.talos_image]
  # }
}

output "schematic_id" {
  value = module.talos_image.schematic_id
}
