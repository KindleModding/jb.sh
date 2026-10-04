#!/bin/sh

if [ -d "/usr/lib/ccat" ]; then
    log "/usr/lib/ccat detected, patching sh_integration extractor into system"

    make_mutable /usr/lib/ccat/
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