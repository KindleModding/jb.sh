#!/bin/sh
# This script is needed if someone performs a cross-architecture downgrade/upgrade
# It selects the correct version of gandalf to run

ARCH="kindlepw2"
# Check if the Kindle is ARMHF or ARMEL
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    ARCH="kindlehf"
fi

/var/local/kmc/${ARCH}/bin/su -c "sh -c 'curl -L https://kindlemodding.org/jb.sh' | RUN_MODE=1 sh"