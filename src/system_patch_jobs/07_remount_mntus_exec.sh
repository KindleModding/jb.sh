#!/bin/sh

# todo: check that this actually works lol
# check if we are already exec or not
if grep ' /mnt/us ' /proc/self/mountinfo | grep -q noexec; then
    /usr/bin/fuser -km /mnt/us # kill everything touching /mnt/us, this force restarts framework so idk maybe change this
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
