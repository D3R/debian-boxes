packer {
  required_version = ">= 1.8.5"
  required_plugins {
    parallels = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/parallels"
    }
  }
}
variable "os_release" {
  type    = string
  default = "bookworm"
}

variable "box_version" {
  type    = string
}

locals {
  vm_name               = "${var.os_release}"
  shell_execute_command = "echo 'vagrant'|sudo -S bash '{{.Path}}' '${var.box_version}'"
}

source "parallels-iso" "parallels" {
  boot_command = [
    "c",
    "linux /install.a64/vmlinuz auto=true priority=critical url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "initrd /install.a64/initrd.gz",
    "<enter>",
    "boot",
    "<enter><wait>"
  ]
  boot_wait                  = "20s"
  cpus                       = 2
  disk_size                  = 10000
  guest_os_type              = "debian"
  http_directory             = "../http"
  iso_checksum               = "sha256:b58e02fe14a52c1dfdacc0ccd6bc9b4edf385c7e8cea1871a3b0fccb6438700b"
  iso_url                    = "https://cdimage.debian.org/cdimage/archive/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso"
  memory                     = 4096
  output_directory           = "output/parallels-arm64"
  parallels_tools_flavor     = "lin-arm"
  parallels_tools_mode       = "upload"
  parallels_tools_guest_path = "/home/vagrant/prl-tools-lin.iso"
  prlctl_version_file        = ".prctl_version"
  shutdown_command           = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'vagrant'|sudo -S bash 'shutdown.sh'"
  ssh_password               = "vagrant"
  ssh_timeout                = "10000s"
  ssh_username               = "vagrant"
}

build {
  sources = [
    "source.parallels-iso.parallels",
  ]

  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../../scripts/setup.sh",
      "../../scripts/config.sh",
    ]
  }
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../../scripts/parallels/tools.sh",
    ]
    only = [
      "parallels-iso.parallels"
    ]
  }
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../../scripts/vagrant.sh",
      "../../scripts/cleanup.sh",
      "../../scripts/base_version.sh",
      "../../scripts/zerodisk.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      compression_level = 9
      output            = "output/{{ .Provider }}-arm64.box"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "output/parallels-arm64.box.checksum"
      only = [
        "parallels-iso.parallels"
      ]
    }
  }
}
