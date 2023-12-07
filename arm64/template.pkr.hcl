packer {
  required_version = ">= 1.8.5"
  required_plugins {
    parallels = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/parallels"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

variable "box_version" {
  type    = string
}
variable "os_codename" {
  type    = string
}
variable "os_releases" {
  # type    = map(string)
  default = {
    # "stretch"   = "9.13.0",
    "buster"    = "10.13.0",
    "bullseye"  = "11.8.0",
    "bookworm"  = "12.1.0",
  }
}
variable "os_hashes" {
  # type    = map(string)
  default = {
    # "stretch"   = "ea321c9de60a6fe9dfaf438b8e16f1945d6d2239e9f0d3cfe6872d4280eba10c",
    "buster"    = "a20a5437e243186ac8d678202cf55a253e8d37df2b187da885796d5071ba829f",
    "bullseye"  = "64787b34b796c6afc5b2526a0aa1b3d00d84aa5f30efe53dbe92d94ff53d6e40",
    "bookworm"  = "b58e02fe14a52c1dfdacc0ccd6bc9b4edf385c7e8cea1871a3b0fccb6438700b",
  }
}

locals {
  hostname = "${var.os_codename}-arm64"
  os_release = var.os_releases[var.os_codename]
  os_sha256 = var.os_hashes[var.os_codename]
  shell_execute_command = "echo 'vagrant'|sudo -S bash '{{.Path}}' '${var.box_version}'"
}

source "parallels-iso" "parallels" {
  boot_command = [
    "c",
    "linux /install.a64/vmlinuz auto=true priority=critical hostname=${local.hostname} url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "initrd /install.a64/initrd.gz",
    "<enter>",
    "boot",
    "<enter><wait>",
  ]
  boot_wait                  = "20s"
  cpus                       = 2
  disk_size                  = 10000
  guest_os_type              = "debian"
  http_directory             = "../http"
  iso_checksum               = "sha256:${local.os_sha256}"
  iso_url                    = "https://cdimage.debian.org/cdimage/archive/${local.os_release}/arm64/iso-cd/debian-${local.os_release}-arm64-netinst.iso"
  memory                     = 4096
  output_directory           = "output/${var.os_codename}-arm64"
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
      "../scripts/setup.sh",
      "../scripts/config.sh",
    ]
  }
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../scripts/parallels/tools.sh",
    ]
    only = [
      "parallels-iso.parallels"
    ]
  }
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../scripts/vagrant.sh",
      "../scripts/cleanup.sh",
      "../scripts/base_version.sh",
      "../scripts/zerodisk.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      compression_level = 9
      output            = "output/${var.os_codename}-arm64.box"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "output/${var.os_codename}-arm64.box.checksum"
      only = [
        "parallels-iso.parallels"
      ]
    }
  }
}
