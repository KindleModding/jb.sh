#!/bin/sh
if { [ $RUN_MODE -eq 0 ] && [ $JAILBROKEN -eq 1 ]; } || \
   { [ -e /tmp/.jb_sh_ran_this_boot ] && [ ! -e /mnt/us/FORCE_JB_REINSTALL ] && [ ! -e /mnt/base-us/FORCE_JB_REINSTALL ]; }; then
    if [ $JB_SH_DEBUG -eq 1 ]; then
        log "Device already jailbroken - exiting."
    fi
    rm -rf /tmp/kmc 2>/dev/null || true
    exit 0
fi
touch /tmp/.jb_sh_ran_this_boot 2>/dev/null || true

# BURN, BABY! BURN!