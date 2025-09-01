#!/bin/sh
# This script is needed if someone performs a cross-architecture downgrade/upgrade
# It selects the correct version of gandalf to run

ARCH="armel"
# Check if the Kindle is ARMHF or ARMEL
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    ARCH="armhf"
fi

/var/local/kmc/${ARCH}/bin/su -c "sh /var/local/kmc/system_patches/patch_system.sh"