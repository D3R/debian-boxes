#!/bin/bash
# virtualbox.sh

set -e

export DEBIAN_FRONTEND="noninteractive"

echo "==> Installing Parallels Tools"
mount -o loop /home/vagrant/prl-tools-lin.iso /mnt 2>&1
bash /mnt/install --install-unattended-with-deps --progress
umount /mnt
rm /home/vagrant/prl-tools-lin.iso
