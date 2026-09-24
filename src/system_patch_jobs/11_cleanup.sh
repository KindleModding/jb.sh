#!/bin/sh
/bin/mount -o remount,ro /
/bin/mount -o exec /mnt/us # Remount as exec
make_immutable /var/local/kmc
log "Done"