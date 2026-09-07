#!/bin/sh
# This file can probably just be replaced by replacing it
# with a /mnt/us remount (see src/jb_sh_jobs/07_cleanup.sh:2)
##if [ ! -f "/MNTUS_EXEC" ] ; then
##    log "Creating the mntus exec flag file"
##    make_mutable "/MNTUS_EXEC"
##    rm -rf "/MNTUS_EXEC"
##    touch "/MNTUS_EXEC"
##    make_immutable "/MNTUS_EXEC"
##fi

# check if we are already exec or not
if grep ' /mnt/us ' /proc/self/mountinfo | grep -q noexec; then
    log "Remounting /mnt/us as exec"
    if ! /bin/mount -o remount,rw,exec /mnt/us; then
        log "Failed to remount as exec trying again"
        sleep 1
        if ! /bin/mount -o remount,rw,exec /mnt/us; then
            log "Failed to remount as exec, trying again"
            sleep 1
            if ! /bin/mount -o remount,rw,exec /mnt/us; then
                log "Failed to remount as exec, trying again"
                sleep 1
                if ! /bin/mount -o remount,rw,exec /mnt/us; then
                    log "Failed to remount as exec after 4 attempts."
                fi
            fi
        fi
    fi
fi