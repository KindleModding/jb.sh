#!/bin/sh

if [ $ROOTLESS -eq 0 ]; then
    if ! /bin/mount -o remount,rw /; then
        log "Failed to remount as rw, trying again"
        sleep 1
        if ! /bin/mount -o remount,rw /; then
            log "Failed to remount as rw, trying again"
            sleep 1
            if ! /bin/mount -o remount,rw /; then
                log "Failed to remount as rw, trying again"
                sleep 1
                if ! /bin/mount -o remount,rw /; then
                    log "Failed to remount as rw after 4 attempts."
                fi
            fi
        fi
    fi
fi