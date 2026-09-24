#!/bin/sh
# Remounting mntus as exec is left for a reboot/rerun, as it breaks the OTA block on non "userstore" systems
/bin/mount -o remount,ro /
make_immutable /var/local/kmc
log "Done"