#!/bin/bash
# base.sh

export DEBIAN_FRONTEND="noninteractive"

# Update the box
echo "==> Updating apt cache"
apt-get -y update

# Install build packages
echo "==> Installing build dependencies"
architecture="amd64"
if [[ "aarch64" = $(uname -m) ]]; then
	architecture="arm64"
fi
apt-get -y install build-essential linux-headers-$architecture ruby-dev libsqlite3-dev

# Install required packages
echo "==> Installing base utilities"
apt-get -y install apt-transport-https curl dirmngr
# NB: openssh-server is mark specifically here so that it doesn't subsequently
# 	  get removed via autoremove when tasksel / task-ssh-server is purged
apt-mark manual openssh-server
