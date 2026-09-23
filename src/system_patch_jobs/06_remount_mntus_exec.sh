#!/bin/sh

if [ $ROOTLESS -eq 0 ]; then # On rootful systems, we can just make the flag
    if [ ! -f "/MNTUS_EXEC" ] ; then
        log "Creating the mntus exec flag file"
        make_mutable "/MNTUS_EXEC"
        rm -rf "/MNTUS_EXEC"
        touch "/MNTUS_EXEC"
        make_immutable "/MNTUS_EXEC"
    fi
else 
    if [ $RERUN -eq 1 ]; then # On rootless, doing this on the first run may cause some issues with jailbreaks that use /mnt/us (Véra, SpiderCat), so leave it for the manual rerun.
        # check if we are already exec or not
        if grep ' /mnt/us ' /proc/self/mountinfo | grep -q noexec; then
            if /usr/bin/fuser -m /mnt/us >/dev/null 2>&1; then
                /usr/bin/fuser -km /mnt/us # kill everything touching /mnt/us, doesn't kill framework when ran via the rerun method
            fi
            /usr/bin/fusermount -u /mnt/us # we can't use /bin/umount for this because fuse sucks
            log "Remounting /mnt/us as exec"
            if ! /bin/mount -o rw,exec /mnt/us; then
                log "Failed to remount as exec trying again"
                sleep 1
                if ! /bin/mount -o rw,exec /mnt/us; then
                    log "Failed to remount as exec, trying again"
                    sleep 1
                    if ! /bin/mount -o rw,exec /mnt/us; then
                        log "Failed to remount as exec, trying again"
                        sleep 1
                        if ! /bin/mount -o rw,exec /mnt/us; then
                            log "Failed to remount as exec after 4 attempts."
                        fi
                    fi
                fi
            fi
        fi
    fi
fi
