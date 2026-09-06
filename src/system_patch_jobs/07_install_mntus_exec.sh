#!/bin/sh
# This file can probably just be replaced by replacing it
# with a /mnt/us remount (see src/jb_sh_jobs/07_cleanup.sh:2)
if [ ! -f "/MNTUS_EXEC" ] ; then
    log "Creating the mntus exec flag file"
    make_mutable "/MNTUS_EXEC"
    rm -rf "/MNTUS_EXEC"
    touch "/MNTUS_EXEC"
    make_immutable "/MNTUS_EXEC"
fi