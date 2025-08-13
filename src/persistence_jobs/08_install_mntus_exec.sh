#!/bin/sh

if [ ! -f "/MNTUS_EXEC" ] ; then
    log "Creating the mntus exec flag file"
    make_mutable "/MNTUS_EXEC"
    rm -rf "/MNTUS_EXEC"
    touch "/MNTUS_EXEC"
    make_immutable "/MNTUS_EXEC"
fi