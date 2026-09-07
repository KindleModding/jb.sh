#!/bin/sh

# todo: check that this actually works lol
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