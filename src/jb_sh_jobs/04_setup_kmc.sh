#!/bin/sh
log "Setting KMC permissions"
chmod -R a+rx /var/local/kmc/sbin/*
chmod -R a+rx /var/local/kmc/kindlepw2/*
chmod -R a+rx /var/local/kmc/kindlehf/*
[ -d /var/local/kmc/xm ] && chmod -R a+rx /var/local/kmc/xm/* 2>/dev/null || true
[ -f /var/local/kmc/run_hotfix.sh ] && chmod a+rx /var/local/kmc/run_hotfix.sh 2>/dev/null || true
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
if [ $ROOTLESS -eq 0 ]; then
    make_immutable /var/local/kmc
fi
# Since the links to these binaries are SOFT links, no additional copying/linking is required

log "Installing libkh binaries"
[ -L /mnt/us/libkh ] && rm -f /mnt/us/libkh 2>/dev/null || true
[ -L /mnt/us/libkh/bin ] && rm -f /mnt/us/libkh/bin 2>/dev/null || true
[ -L /mnt/us/libkh/lib ] && rm -f /mnt/us/libkh/lib 2>/dev/null || true
mkdir -p "/mnt/us/libkh/bin" "/mnt/us/libkh/lib"
rm -f /mnt/us/libkh/bin/fbink /mnt/us/libkh/lib/libfbink.so
cp -f "/var/local/kmc/${PLATFORM}/bin/fbink" "/mnt/us/libkh/bin/fbink" # Yeah we do copying bc userstore is funky
cp -f "/var/local/kmc/${PLATFORM}/lib/libfbink.so" "/mnt/us/libkh/lib/libfbink.so" 2>/dev/null || true
chmod a+rx "/mnt/us/libkh/bin/fbink" "/mnt/us/libkh/lib/libfbink.so" 2>/dev/null || true

log "Deleting old hotfix"
rm -f /mnt/base-us/documents/*.run_hotfix /mnt/us/documents/*.run_hotfix 2>/dev/null || true
mkdir -p /mnt/us/documents 2>/dev/null || true
echo "Run Hotfix" > "/mnt/us/documents/Run Hotfix.run_hotfix"

log "Setting up hotfix and emergency runners"
if [ -s "/var/local/appreg.db" ] && [ ! -s "/var/local/appreg.db.stock" ] && command -v sqlite3 >/dev/null 2>&1; then
    _appreg_ic="$(echo "PRAGMA busy_timeout = 5000; PRAGMA integrity_check;" | sqlite3 /var/local/appreg.db 2>/dev/null | tail -n 1)"
    if [ "$_appreg_ic" = "ok" ]; then
        cp -f /var/local/appreg.db /var/local/appreg.db.stock 2>/dev/null || true
        sync
    fi
fi
log "$(cat /var/local/kmc/sql/appreg_register_hotfix.sql | sqlite3 /var/local/appreg.db)"
log "$(cat /var/local/kmc/sql/appreg_register_emergency.sql | sqlite3 /var/local/appreg.db)"

if [ ! -d "/usr/lib/ccat" ]; then
    log "Setting up sh_integration"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_1.sql | sqlite3 /var/local/appreg.db)"
    NUM=$(echo "PRAGMA busy_timeout = 5000; SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor';" | sqlite3 /var/local/appreg.db --line | awk '/^[[:space:]]*timeout[[:space:]]*=/ { next } NF == 0 && !seen { next } { seen=1; print }' | wc -l)
    if [ ! $NUM -eq 7 ]; then
        log "Failed to setup sh_integration, trying again..."
        sleep 1
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_1.sql | sqlite3 /var/local/appreg.db)"
        NUM=$(echo "PRAGMA busy_timeout = 5000; SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor';" | sqlite3 /var/local/appreg.db --line | awk '/^[[:space:]]*timeout[[:space:]]*=/ { next } NF == 0 && !seen { next } { seen=1; print }' | wc -l)
        if [ ! $NUM -eq 7 ]; then
            log "Failed to setup sh_integraion - please report to Hackerdude"
        fi
    fi
else
    log "/usr/lib/ccat detected - deferring sh_integration setup to system patch stage"
fi