#!/bin/sh
# Based on Marek's "Disable ADs on ad-supported devices" scriptlet

log "Removing ad folders"
rm -rf /var/local/adunits
rm -rf /mnt/us/.assets

log "Disabling adunits in appreg.db"
log "$(cat /var/local/kmc/sql/appreg_disable_adunits.sql | sqlite3 /var/local/appreg.db)"