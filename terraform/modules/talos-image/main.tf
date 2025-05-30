variable "talos_version" {
  type = string
}
variable "platform" {
  type    = string
  default = "nocloud"
}

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
  }
}

locals {
  build_dir    = "${path.module}/build"
  archive_name = "talos-${var.talos_version}.tar.gz"
}

# data "talos_image_factory_extensions_versions" "extensions" {
#   talos_version = var.talos_version
#   filters = {
#     names = [
#       "qemu-guest-agent"
#     ]
#   }
# }

resource "talos_image_factory_schematic" "image" {
  schematic = yamlencode({
    customization = {
      extraKernelArgs = [
        "talos.dashboard.disabled=1"
      ]
      systemExtensions = {
        # officialExtensions = data.talos_image_factory_extensions_versions.extensions.extensions_info.*.name
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  schematic_id  = talos_image_factory_schematic.image.id
  talos_version = var.talos_version
  platform      = var.platform
}

resource "terraform_data" "generate_image" {
  provisioner "local-exec" {
    command     = "${path.module}/scripts/incus-image.sh"
    working_dir = path.module
    environment = {
      IMAGE_URL     = data.talos_image_factory_urls.this.urls.disk_image
      TALOS_VERSION = var.talos_version
    }
  }

  triggers_replace = [
    data.talos_image_factory_urls.this.urls.disk_image
  ]
}

output "schematic_id" {
  value = resource.talos_image_factory_schematic.image.id
}

output "archive_path" {
  value = "${local.build_dir}/${local.archive_name}"
}
