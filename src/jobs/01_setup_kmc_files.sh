#!/bin/sh

###
# Fix permissions for KMC (MKK doesn't need this)
###
log "Checking storage..."
# We track how much storage the currently installed hotfix takes (since we're gonna delete it, it shouldn't count)
STORAGE_FREEABLE=$((0))

if [ -d "/var/local/kmc" ]; then
    STORAGE_FREEABLE=$(($STORAGE_FREEABLE + $(df -k /var/local/kmc | tail -n 1 | tr -s ' ' | cut -d' ' -f4)))
fi
if [ -d "/var/local/mkk" ]; then
    STORAGE_FREEABLE=$(($STORAGE_FREEABLE + $(df -k /var/local/mkk | tail -n 1 | tr -s ' ' | cut -d' ' -f4)))
fi

# Make sure we have enough space in /var/local to unpack our KMC and MKK tars
if [ "$(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)" -lt "$(($(df -k /tmp/kmc | cut -f1) - $STORAGE_FREEABLE))" ] ; then
    log "not enough space left in varlocal"
    log "Needed: $(($(df -k /tmp/kmc | cut -f1) - $STORAGE_FREEABLE))"
    log "Available: $(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)"
    rm -rf /tmp/kmc
    return 1
fi

make_mutable /var/local/mkk
rm -rf /var/local/mkk
mkdir /var/local/mkk

make_mutable "/var/local/kmc"
cp -rf /tmp/kmc/* /var/local/kmc

log "Setting KMC permissions"
chmod -R a+rx /var/local/kmc/armel/*
chmod -R a+rx /var/local/kmc/armhf/*
#chmod 0664 /var/local/kmc/hotfix/kmc.conf
#chmod a+rx /var/local/kmc/hotfix/hotfix.sh

log "Fixing KMC gandalf permissions"
for gandalf_arch in armel armhf; do
    make_mutable "/var/local/kmc/${gandalf_arch}/bin/gandalf"
    chown root:root "/var/local/kmc/${gandalf_arch}/bin/gandalf"
    chmod a+rx "/var/local/kmc/${gandalf_arch}/bin/gandalf"
    chmod +s "/var/local/kmc/${gandalf_arch}/bin/gandalf"
    ln -sf "/var/local/kmc/armel/bin/gandalf" "/var/local/kmc/armel/bin/su"
    ln -sf "/var/local/kmc/armhf/bin/gandalf" "/var/local/kmc/armhf/bin/su"
    make_immutable "/var/local/kmc/${gandalf_arch}/bin/gandalf"
done


log "Establishing Gandalf links"
rm -rf "/var/local/kmc/lib"
rm -rf "/var/local/kmc/bin"
ln -sf "/var/local/kmc/${ARCH}/lib" "/var/local/kmc/lib"
ln -sf "/var/local/kmc/${ARCH}/bin" "/var/local/kmc/bin"
ln -sf "/var/local/kmc/bin/gandalf" "/var/local/mkk/gandalf"
make_mutable /var/local/mkk
ln -sf "/var/local/mkk/gandalf" "/var/local/mkk/su"
make_immutable /var/local/mkk
make_immutable /var/local/kmc

log "Installing libkh binaries"
mkdir -p "/mnt/us/libkh/bin"
rm -f /mnt/us/libkh/bin/fbink
cp -f "/var/local/mkk/${ARCH}/bin/fbink" "/mnt/us/libkh/bin/fbink" # Yeah we do copying bc userstore is funky
chmod a+rx "/mnt/us/libkh/bin/fbink"

# Since the links to these binaries are SOFT links, no additional copying/linking is required

# Not needed anymore
rm -rf /tmp/kmc


log "Setting up sh_integration"
cat /var/local/kmc/sql/appreg_register_sh_integration.sql | sqlite3 /var/local/appreg.db

log "Setting up persistence"
cat /var/local/kmc/sql/appreg_register_persistence_runner.sql | sqlite3 /var/local/appreg.db