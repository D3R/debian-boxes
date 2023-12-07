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
  }
}

# variable "box_no_release" {
#   type    = string
#   default = "true"
# }

# variable "cloud_token" {
#   type    = string
#   default = ""
# }

# variable "base_box_channel" {
#   type    = string
#   default = "stable"
# }

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/archive/11.7.0/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "eb3f96fd607e4b67e80f4fc15670feb7d9db5be50f4ca8d0bf07008cb025766b"
}

variable "os_release" {
  type    = string
  default = "bullseye"
}

variable "box_version" {
  type    = string
}

locals {
  vm_name               = "${var.os_release}"
  shell_execute_command = "echo 'vagrant'|sudo -S bash '{{.Path}}' '${var.box_version}'"
}

source "virtualbox-iso" "virtualbox" {
  boot_command            = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg hostname=${local.vm_name}",
    "<enter><wait>"
  ]
  boot_wait               = "10s"
  disk_size               = "10000"
  guest_additions_mode    = "disable"
  guest_os_type           = "Debian_64"
  headless                = true
  http_directory          = "../http"
  iso_checksum            = "sha256:${var.iso_checksum}"
  iso_url                 = "${var.iso_url}"
  output_directory        = "output/virtualbox"
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

source "parallels-iso" "parallels" {
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg hostname=${local.vm_name}",
    "<enter><wait>"
    # "c",
    # "linux /install.a64/vmlinuz auto=true priority=critical url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    # "<enter>",
    # "initrd /install.a64/initrd.gz",
    # "<enter>",
    # "boot",
    # "<enter><wait>"
  ]
  boot_wait                  = "10s"
  cpus                       = 1
  disk_size                  = 10000
  guest_os_type              = "debian"
  http_directory             = "../http"
  iso_checksum               = "sha256:${var.iso_checksum}"
  iso_url                    = "${var.iso_url}"
  memory                     = 4096
  output_directory           = "output/parallels"
  parallels_tools_flavor     = "lin"
  parallels_tools_mode       = "upload"
  prlctl_version_file        = ".prctl_version"
  shutdown_command           = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'vagrant'|sudo -S bash 'shutdown.sh'"
  ssh_password               = "vagrant"
  ssh_port                   = 22
  ssh_timeout                = "10000s"
  ssh_username               = "vagrant"
}

build {
  sources = [
    "source.virtualbox-iso.virtualbox",
    "source.parallels-iso.parallels",
  ]
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../../../scripts/common/setup.sh",
      "../../../scripts/base/packages.sh",
      "../../../scripts/base/config.sh",
      "../../../scripts/common/upgrade.sh",
    ]
  }
  # provisioner "shell" {
  #   execute_command = local.shell_execute_command
  #   scripts = [
  #     "../../../scripts/common/parallels/tools.sh",
  #   ]
  #   only = [
  #     "parallels-iso.parallels"
  #   ]
  # }
  provisioner "shell" {
    execute_command = local.shell_execute_command
    scripts = [
      "../../../scripts/base/vagrant.sh",
      "../../../scripts/common/cleanup.sh",
      "../../../scripts/base/base_version.sh",
      "../../../scripts/common/zerodisk.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      compression_level = 9
      output            = "output/{{ .Provider }}-amd64.box"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "output/parallels-amd64.box.checksum"
      only = [
        "parallels-iso.parallels"
      ]
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "output/virtualbox-amd64.box.checksum"
      only = [
        "virtualbox-iso.virtualbox"
      ]
    }
    # post-processor "vagrant-cloud" {
    #   access_token        = "${var.cloud_token}"
    #   box_download_url    = "https://d3r-vagrant-stack.s3.eu-west-2.amazonaws.com/stable/{{ .Provider }}-amd64-${var.box_version}.box"
    #   box_tag             = "d3r/${var.os_release}"
    #   no_release          = "${var.box_no_release}"
    #   version             = "${var.box_version}"
    #   keep_input_artifact = true
    # }
  }
}
