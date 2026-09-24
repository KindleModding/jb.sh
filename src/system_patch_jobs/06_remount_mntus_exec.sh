#!/bin/sh

if [ $ROOTLESS -eq 0 ]; then # On rootful systems, we can just make the flag
    if [ ! -f "/MNTUS_EXEC" ] ; then
        log "Creating the mntus exec flag file"
        make_mutable "/MNTUS_EXEC"
        rm -rf "/MNTUS_EXEC"
        touch "/MNTUS_EXEC"
        make_immutable "/MNTUS_EXEC"
    fi
fi 
# on rootless systems, this is handled by 11_cleanup.sh:3
