#!/bin/bash
# virtualbox.sh

export DEBIAN_FRONTEND="noninteractive"

VERSION="latest"

echo "==> Installing VirtualBox Guest Additions $VERSION"
# Install dependencies
apt-get -y install linux-headers-$(uname -r) build-essential dkms
if [[ $? -ne 0 ]]; then
    echo "==> ERROR: linux-headers install failed!"
    exit 1
fi

# Work out the latest version
if [[ $VERSION == "latest" ]]; then
    VERSION=$(curl -s http://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
    echo "==> Latest Version : $VERSION"
else
    echo "==> Pinned Version : $VERSION"
fi

# download VB ISO
download_url="http://download.virtualbox.org/virtualbox/$VERSION/VBoxGuestAdditions_$VERSION.iso"
echo "==> Downloading guest additions from $download_url"
cd /tmp
wget --quiet $download_url
if [[ $? -ne 0 ]]; then
    echo "==> ERROR: guest additions download failed!"
    exit 1
fi

echo "==> Run install script of VirtualBox Guest Additions $VERSION"
mount -o loop VBoxGuestAdditions_$VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm VBoxGuestAdditions_$VERSION.iso
