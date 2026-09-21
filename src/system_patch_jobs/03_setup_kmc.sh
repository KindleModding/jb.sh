#!/bin/sh
# Todo: turn lines 6-9 into a bind-mount instead of modifying rootfs, should be easy enough.
if [ -d "/usr/lib/ccat" ]; then
    log "/usr/lib/ccat detected, patching sh_integration extractor into system"

    setup_bind_mount /usr/lib/ccat # usually like 500kb, should be fine
    make_mutable /usr/lib/ccat/sh_integration_extractor.so
    cp -af /var/local/kmc/lib/sh_integration_extractor.so /usr/lib/ccat/sh_integration_extractor.so
    make_immutable /usr/lib/ccat/sh_integration_extractor.so

    log "Setting up sh_integration"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_2.sql | sqlite3 /var/local/appreg.db)"
    NUM=$(echo "SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor'" | sqlite3 /var/local/appreg.db --line | wc -l)
    if [ ! $NUM -eq 7 ]; then
        log "Failed to setup sh_integration, trying again..."
        sleep 1
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_2.sql | sqlite3 /var/local/appreg.db)"
        NUM=$(echo "SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor'" | sqlite3 /var/local/appreg.db --line | wc -l)
        if [ ! $NUM -eq 7 ]; then
            log "Failed to setup sh_integraion - please report to Hackerdude"
        fi
    fi
fi