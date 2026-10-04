#!/bin/sh

log "Stopping OTA"

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

# Delete .tmp.partial and .bin files
rm -rf /mnt/us/*.tmp.partial
rm -rf /mnt/us/*.bin