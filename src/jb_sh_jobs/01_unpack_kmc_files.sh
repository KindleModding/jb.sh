#!/bin/sh

###
# Fix permissions for KMC (MKK doesn't need this)
###
log "Checking storage..."
# We track how much storage the currently installed hotfix/monolith takes (since we're gonna delete it, it shouldn't count)
STORAGE_FREEABLE=$((0))

log "Reading storage from folders"
if [ -d "/var/local/kmc" ]; then
    STORAGE_FREEABLE=$(($STORAGE_FREEABLE + $(du -ks /var/local/kmc | cut -f1)))
fi
if [ -d "/var/local/mkk" ]; then
    STORAGE_FREEABLE=$(($STORAGE_FREEABLE + $(du -ks /var/local/mkk | cut -f1)))
fi

# Make sure we have enough space in /var/local to unpack our KMC and MKK tars
if [ "$(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)" -lt "$(($(du -ks /tmp/kmc | cut -f1) - $STORAGE_FREEABLE))" ] ; then
    log "not enough space left in varlocal"
    log "Needed: $(($(du -ks /tmp/kmc | cut -f1) - $STORAGE_FREEABLE))"
    log "Available: $(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)"
    rm -rf /tmp/kmc
    return 1
fi

log "Removing mkk"
make_mutable /var/local/mkk
rm -rf /var/local/mkk
mkdir /var/local/mkk

log "Unpacking KMC"
make_mutable "/var/local/kmc"
mkdir -p /var/local/kmc
cp -rf /tmp/kmc/* /var/local/kmc
rm -rf /tmp/kmc

log "Running system patch script"
# Run system patch script (what was once the hotfix)
sh /var/local/kmc/system_patches/patch_system.sh # Run it directly since jb.sh MUST be run as root