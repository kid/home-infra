include {
  path = find_in_parent_folders()
}

dependency "isos" {
  config_path = "../../proxmox-isos"
}

terraform {
  source = "${get_repo_root()}//terraform/stacks/prtsrv"
}

inputs = {
  flatcar_image_id = dependency.isos.outputs.flatcar_beta_file_id
}

