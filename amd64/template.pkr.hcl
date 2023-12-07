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
  hostname = "${var.os_codename}-amd64"
  os_release = var.os_releases[var.os_codename]
  os_sha256 = var.os_hashes[var.os_codename]
  shell_execute_command = "echo 'vagrant'|sudo -S bash '{{.Path}}' '${var.box_version}'"
}

source "virtualbox-iso" "virtualbox" {
  boot_command            = [
    "<esc><wait>",
    "auto=true priority=critical hostname=${local.hostname} url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "boot",
    "<enter><wait>",
  ]
  boot_wait               = "20s"
  disk_size               = "10000"
  guest_additions_mode    = "disable"
  guest_os_type           = "Debian_64"
  headless                = true
  http_directory          = "../http"
  iso_checksum            = "sha256:${var.iso_checksum}"
  iso_url                 = "${var.iso_url}"
  output_directory        = "output/base-virtualbox"
  shutdown_command        = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'vagrant'|sudo -S bash 'shutdown.sh'"
  ssh_password            = "vagrant"
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  vboxmanage              = [
    [
      "modifyvm",
      "{{ .Name }}", "--memory", "4096",
    ],
    [
      "modifyvm",
      "{{.Name}}", "--cpus", "1",
    ]
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
