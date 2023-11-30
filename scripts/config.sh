#!/bin/bash
# dep.sh

export DEBIAN_FRONTEND="noninteractive"

# set locales
rm -rf /usr/lib/locale/*
echo "==> Setting locale"
echo "# set locale
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
" > /etc/locale.gen
echo "# default locale
LANG=en_GB.UTF-8
" > /etc/default/locale
locale-gen &> /dev/null

# Tweak sshd to prevent DNS resolution (speed up logins)
echo "==> Tweak SSH..."
echo 'UseDNS no' >> /etc/ssh/sshd_config

echo "==> Tweak systemd login service"
echo "RemoveIPC=no" >> /etc/systemd/logind.conf

# Adding a 2 sec delay to the interface up, to make the dhclient happy
echo "==> Adjust network interface..."
echo "pre-up sleep 2" >> /etc/network/interfaces
