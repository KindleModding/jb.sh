#!/bin/sh

if [ -s "/var/local/appreg.db" ] && [ ! -s "/var/local/appreg.db.stock" ] && command -v sqlite3 >/dev/null 2>&1; then
    _appreg_ic="$(echo "PRAGMA busy_timeout = 5000; PRAGMA integrity_check;" | sqlite3 /var/local/appreg.db 2>/dev/null | tail -n 1)"
    if [ "$_appreg_ic" = "ok" ]; then
        cp -f /var/local/appreg.db /var/local/appreg.db.stock 2>/dev/null || true
        sync
    fi
fi

if [ -d "/usr/lib/ccat" ]; then
    log "/usr/lib/ccat detected, patching sh_integration extractor into system"

    "$CHATTR" -i -d /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so 2>/dev/null || true
    cp -af /var/local/kmc/lib/sh_integration_extractor.so /usr/lib/ccat/sh_integration_extractor.so
    chown root:root /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so 2>/dev/null || true
    chmod 0755 /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so 2>/dev/null || true
    make_immutable /usr/lib/ccat/sh_integration_extractor.so

    log "Setting up sh_integration"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
    log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_2.sql | sqlite3 /var/local/appreg.db)"
    NUM=$(echo "PRAGMA busy_timeout = 5000; SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor';" | sqlite3 /var/local/appreg.db --line | awk '/^[[:space:]]*timeout[[:space:]]*=/ { next } NF == 0 && !seen { next } { seen=1; print }' | wc -l)
    if [ ! $NUM -eq 7 ]; then
        log "Failed to setup sh_integration, trying again..."
        sleep 1
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_common.sql | sqlite3 /var/local/appreg.db)"
        log "$(cat /var/local/kmc/sql/appreg_register_sh_integration_2.sql | sqlite3 /var/local/appreg.db)"
        NUM=$(echo "PRAGMA busy_timeout = 5000; SELECT * FROM properties WHERE handlerId='tech.hackerdude.shell_integration.extractor';" | sqlite3 /var/local/appreg.db --line | awk '/^[[:space:]]*timeout[[:space:]]*=/ { next } NF == 0 && !seen { next } { seen=1; print }' | wc -l)
        if [ ! $NUM -eq 7 ]; then
            log "Failed to setup sh_integraion - please report to Hackerdude"
        fi
    fi
fi