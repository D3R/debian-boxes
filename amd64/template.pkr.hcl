packer {
  required_version = ">= 1.8.5"
  required_plugins {
    parallels = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/parallels"
    }
    virtualbox = {
      version = ">= 1.0"
      source  = "github.com/hashicorp/virtualbox"
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
    # "buster"    = "10.13.0",
    "bullseye"  = "11.10.0",
    "bookworm"  = "12.5.0",
  }
}
variable "os_hashes" {
  # type    = map(string)
  default = {
    # "buster"    = "75aa64071060402a594dcf1e14afd669ca0f8bf757b56d4c9c1a31b8f7c8f931",
    "bullseye"  = "721ef40ba86c01b555ea85bb4ca7917d28cb65d56e57a0f56af90443f0aec6a3",
    "bookworm"  = "013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f",
  }
}

locals {
  hostname = "${var.os_codename}-amd64"
  os_release = var.os_releases[var.os_codename]
  os_sha256 = var.os_hashes[var.os_codename]
  shell_execute_command = "echo 'vagrant'|sudo -S bash '{{.Path}}' '${var.box_version}'"
}

source "virtualbox-iso" "virtualbox" {
  boot_command            = [
    "<esc><wait>",
    "auto priority=critical hostname=${local.hostname} url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter><wait>",
  ]
  boot_wait               = "20s"
  disk_size               = "10000"
  guest_additions_mode    = "disable"
  guest_os_type           = "Debian_64"
  headless                = true
  http_directory          = "../http"
  iso_checksum            = "sha256:${local.os_sha256}"
  iso_url                 = "https://cdimage.debian.org/cdimage/archive/${local.os_release}/amd64/iso-cd/debian-${local.os_release}-amd64-netinst.iso"
  output_directory        = "output/base-virtualbox"
  shutdown_command        = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'vagrant'|sudo -S bash 'shutdown.sh'"
  ssh_password            = "vagrant"
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  vboxmanage              = [
    [ "modifyvm", "{{ .Name }}", "--memory",                  "4096" ],
    [ "modifyvm", "{{.Name}}",   "--cpus",                    "1"    ],
    [ "modifyvm", "{{.Name}}",   "--nat-localhostreachable1", "on"   ],
  ]
  virtualbox_version_file = ".vbox_version"
}

build {
  sources = [
    "source.virtualbox-iso.virtualbox",
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
      "../scripts/virtualbox/guest-additions.sh",
    ]
    only = [
      "virtualbox-iso.virtualbox"
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
      output            = "output/${var.os_codename}-amd64.box"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "output/${var.os_codename}-amd64.box.checksum"
      only = [
        "virtualbox-iso.virtualbox"
      ]
    }
  }
}
