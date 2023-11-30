#!/bin/bash

set -e

# Zero out the free space to save space in the final image

# count free space
COUNT=`df --sync -mP / | tail -n1  | awk -F ' ' '{print $4}'`
COUNT=$((COUNT -= 1))
echo "==> Zeroing $COUNT MB free space..."

# writing zero bytes to the wipefile
dd if=/dev/zero of=/tmp/wipe bs=1M count=$COUNT

# Sync to ensure that the delete completes before this moves on.
sync; sleep 3; sync;

# remove
rm -rf /tmp/wipe

echo "==> Zeroing completed"

echo "==> **********************************"
echo "==> *** Image creation is complete ***"
echo "==> **********************************"

exit 0
