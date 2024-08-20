#!/bin/bash
# cleanup.sh

set -e

box_version=$1
datestamp=$(/usr/bin/date +%Y%m%d%H%M)

# Install build packages
architecture="amd64"
if [[ "aarch64" = $(uname -m) ]]; then
    architecture="arm64"
fi
build_packages=(
    "build-essential"
    "linux-headers-$architecture"
    "ruby-dev"
    "libsqlite3-dev"
)
echo "==> Purging build packages..."
apt-get -y purge ${build_packages[@]}

echo "==> Removing big packages"
dpkg --list \
    | awk '{ print $2 }' \
    | grep linux-source \
    | xargs apt-get -y purge;
dpkg --list \
    | awk '{ print $2 }' \
    | grep -- '-doc$' \
    | xargs apt-get -y purge;

# Removing DHCP, cache, ...
echo "==> Cleaning up /var ..."
# DHCP leases
rm /var/lib/dhcp/*
# empty cache
find /var/cache -type f -exec rm -rf {} \;

echo "==> Setting up dpkg excludes"
cat <<_EOF_ | cat >> /etc/dpkg/dpkg.cfg.d/90-firmware-excludes
path-exclude=/lib/firmware/*
path-exclude=/usr/share/doc/linux-firmware/*
_EOF_
cat <<_EOF_ | cat >> /etc/dpkg/dpkg.cfg.d/90-locales
path-exclude=/usr/share/locale/*
path-exclude=/usr/share/gnome/help/*/*
path-exclude=/usr/share/doc/kde/HTML/*/*
path-exclude=/usr/share/omf/*/*-*.emf
path-exclude=/usr/share/man/*
# Paths to keep
path-include=/usr/share/locale/locale.alias
path-include=/usr/share/locale/en/*
path-include=/usr/share/locale/en_GB.UTF-8/*
path-include=/usr/share/locale/en_US.UTF-8/*
path-include=/usr/share/gnome/help/*/C/*
path-include=/usr/share/gnome/help/*/en/*
path-include=/usr/share/gnome/help/*/en_GB.UTF-8/*
path-include=/usr/share/gnome/help/*/en_US.UTF-8/*
path-include=/usr/share/doc/kde/HTML/C/*
path-include=/usr/share/doc/kde/HTML/en/*
path-include=/usr/share/doc/kde/HTML/en_GB.UTF-8/*
path-include=/usr/share/doc/kde/HTML/en_US.UTF-8/*
path-include=/usr/share/omf/*/*-en.emf
path-include=/usr/share/omf/*/*-en_GB.UTF-8.emf
path-include=/usr/share/omf/*/*-en_US.UTF-8.emf
path-include=/usr/share/omf/*/*-C.emf
path-include=/usr/share/locale/languages
path-include=/usr/share/locale/all_languages
path-include=/usr/share/locale/currency/*
path-include=/usr/share/locale/l10n/*
path-include=/usr/share/man/en/*
path-include=/usr/share/man/en_GB.UTF-8/*
path-include=/usr/share/man/en_US.UTF-8/*
path-include=/usr/share/man/man[0-9]/*
_EOF_

# Delete the massive firmware packages
rm -rf /lib/firmware/*
rm -rf /usr/share/doc/linux-firmware/*

echo "==> Removing foreign lanuguage man files"
rm -rf /usr/share/man/??
rm -rf /usr/share/man/??_*

echo "==> Removing log files"
find /var/log/ -name *.log -exec rm -f {} \;

# Make sure Udev doesn't block our network
# echo "==> Cleaning up udev rules"
# rm -f /etc/udev/rules.d/70-persistent-net.rules
# # The below causes kernel builds to fail...
# #mkdir /etc/udev/rules.d/70-persistent-net.rules
# rm -rf /dev/.udev/
# rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up /usr ..."
# remove doc
rm -rf /usr/share/doc/*

if [ -d /home/vagrant ]; then
    echo "==> Cleaning up virtualbox guest data ..."
    # Remove source files
    rm -rf /usr/src/vboxguest-*
    echo "==> Cleaning up vagrant home directory ..."
    rm -f /home/vagrant/VBoxGuestAdditions_*.iso
    # remove bash history
    unset histfile
    rm -rf /home/vagrant/.bash_history
    rm -f /home/vagrant/.mysql_history
fi

echo "==> Removing unnecessary packages..."
apt-get -y purge \
    debian-faq \
    debian-faq-de \
    debian-faq-fr \
    debian-faq-it \
    debian-faq-zh-cn \
    doc-debian \
    installation-report \
    laptop-detect \
    manpages \
    mutt \
    popularity-contest \
    ppp \
    pppconfig \
    pppoe \
    pppoeconf \
    read-edid \
    reportbug \
    tasksel \
    tcsh \
    w3m \
    wamerican \
    wireless-regdb

echo "==> Cleaning up packages ..."
# packages
apt-get -y autoremove
apt-get -y clean
apt-get -y autoclean

echo "==> Removing apt lists"
find /var/lib/apt/lists -type f -exec rm -f {} \;

echo "==> Resetting machine id"
truncate -s 0 /etc/machine-id
truncate -s 0 /var/lib/dbus/machine-id

echo "==> Adding box information"
echo "${box_version} ${datestamp}" > /etc/box_version
