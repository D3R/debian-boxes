#!/bin/bash

set -e

box_version=$1
datestamp=$(/usr/bin/date +%Y%m%d%H%M)

echo "==> Adding base box information"
echo "${box_version} ${datestamp}" > /etc/base_box_version
