#!/bin/bash
# base.sh

set -e

export DEBIAN_FRONTEND="noninteractive"

# Update the box
echo "==> Updating apt cache"
apt-get -y update

# Update all packages
echo "==> Upgrading all packages"
apt-get -y dist-upgrade