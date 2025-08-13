#!/bin/sh

log "Disabling OTA"

# Kill them asap
killall otaupd -s -9
killall otav3 -s -9

if [ -f "/usr/bin/otaupd" ] ; then
    log "Renaming otaupd"
    make_mutable /usr/bin/otaupd
    mv /usr/bin/otaupd /usr/bin/otaupd.bck
fi

if [ -f "/usr/bin/otav3" ] ; then
    log "Renaming otav3"
    make_mutable /usr/bin/otav3
    mv /usr/bin/otav3 /usr/bin/otav3.bck
fi