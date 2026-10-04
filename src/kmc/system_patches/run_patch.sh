#!/bin/sh
# This script is needed if someone performs a cross-architecture downgrade/upgrade
# It selects the correct version of gandalf to run

PLATFORM="kindlepw2"
# Check if the Kindle is kindlehf or kindlepw2
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    PLATFORM="kindlehf"
fi

/var/local/kmc/${PLATFORM}/bin/su -c "sh /var/local/kmc/system_patches/patch_system.sh"