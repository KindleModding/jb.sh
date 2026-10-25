#!/bin/sh
# Based on Marek's "Disable ADs on ad-supported devices" scriptlet

log "Removing ad folders"
if [ -d "/var/local/adunits" ]; then
    rm -rf /var/local/adunits
fi

if [ -d "/mnt/us/.assets" ]; then
    rm -rf /mnt/us/.assets
fi


log "Disabling adunits in appreg.db"
log "$(cat /var/local/kmc/sql/appreg_disable_adunits.sql | sqlite3 /var/local/appreg.db)"