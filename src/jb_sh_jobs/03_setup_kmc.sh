#!/bin/sh
log "Setting KMC permissions"
chmod -R a+rx /var/local/kmc/sbin/*
chmod -R a+rx /var/local/kmc/kindlepw2/*
chmod -R a+rx /var/local/kmc/kindlehf/*
chmod 0664 /var/local/kmc/system_patches/kmc.conf
chmod a+rx /var/local/kmc/system_patches/patch_system.sh
chmod a+rx /var/local/kmc/system_patches/run_patch.sh

log "Setting KMC gandalf permissions"
for gandalf_platform in kindlepw2 kindlehf; do
    make_mutable "/var/local/kmc/${gandalf_platform}/bin/gandalf"
    chown root:root "/var/local/kmc/${gandalf_platform}/bin/gandalf"
    chmod a+rx "/var/local/kmc/${gandalf_platform}/bin/gandalf"
    chmod +s "/var/local/kmc/${gandalf_platform}/bin/gandalf"
    ln -sf "/var/local/kmc/${gandalf_platform}/bin/gandalf" "/var/local/kmc/${gandalf_platform}/bin/su"
    make_immutable "/var/local/kmc/${gandalf_platform}/bin/gandalf"
done


log "Establishing Gandalf links"
rm -rf "/var/local/kmc/lib"
rm -rf "/var/local/kmc/bin"
ln -sf "/var/local/kmc/${PLATFORM}/lib" "/var/local/kmc/lib"
ln -sf "/var/local/kmc/${PLATFORM}/bin" "/var/local/kmc/bin"
ln -sf "/var/local/kmc/bin/gandalf" "/var/local/mkk/gandalf"
make_mutable /var/local/mkk
ln -sf "/var/local/mkk/gandalf" "/var/local/mkk/su"
make_immutable /var/local/mkk
make_immutable /var/local/kmc
# Since the links to these binaries are SOFT links, no additional copying/linking is required

log "Installing libkh binaries"
mkdir -p "/mnt/us/libkh/bin"
rm -f /mnt/us/libkh/bin/fbink
cp -f "/var/local/kmc/${PLATFORM}/bin/fbink" "/mnt/us/libkh/bin/fbink" # Yeah we do copying bc userstore is funky
chmod a+rx "/mnt/us/libkh/bin/fbink"

log "Deleting old hotfix"
rm /mnt/us/documents/*.run_hotfix

log "Setting up hotfix and emergency runners"
log "$(cat /var/local/kmc/sql/appreg_register_hotfix.sql | sqlite3 /var/local/appreg.db)"
log "$(cat /var/local/kmc/sql/appreg_register_emergency.sql | sqlite3 /var/local/appreg.db)"

log "Setting up sh_integration"
log "$(cat /var/local/kmc/sql/appreg_register_sh_integration.sql | sqlite3 /var/local/appreg.db)"
NUM=$(echo "SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor'" | sqlite3 /var/local/appreg.db --line | wc -l)
if [ ! $NUM -eq 7 ]; then
    log "Failed to setup sh_integration, trying again..."
    sleep 1
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration.sql | sqlite3 /var/local/appreg.db)"
    NUM=$(echo "SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor'" | sqlite3 /var/local/appreg.db --line | wc -l)
    if [ ! $NUM -eq 7 ]; then
        log "Failed to setup sh_integraion - please report to Hackerdude"
    fi
fi