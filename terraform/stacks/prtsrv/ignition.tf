data "ignition_config" "vm" {
  users = [
    data.ignition_user.kid.rendered,
  ]

  files = [
    data.ignition_file.printers.rendered,
  ]

  systemd = [
    # data.ignition_systemd_unit.docker.rendered,
    data.ignition_systemd_unit.cupsd.rendered,
  ]
}

data "ignition_user" "kid" {
  name = "kid"
  ssh_authorized_keys = [
    trimspace(file("~/.ssh/id_rsa.pub"))
  ]
  groups = ["sudo", "systemd-journal", "docker"]
}

# data "ignition_link" "docker" {
#   path = "/etc/systemd/system/multi-user.target.wants/docker.service"
#   target = "/usr/lib/systemd/system/docker.service"
# }
#
# data "ignition_systemd_unit" "docker" {
#   name = "docker.service"
#   enabled = true
# }

data "ignition_systemd_unit" "cupsd" {
  name    = "cupsd.service"
  content = file("${path.module}/files/cupsd.service")
}

data "ignition_file" "printers" {
  path = "/etc/cups/printers.conf"

  content {
    content = file("${path.module}/files/printers.conf")
  }
}

output "ignition_config" {
  value = data.ignition_config.vm.rendered
}
