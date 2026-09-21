#!/bin/sh
command_jsons="/app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json /usr/share/webkit-1.0/pillow/debug_cmds.json"
patch_bin="/var/local/kmc/bin/kmc_system_patcher"

for filepath in $command_jsons; do
    if [ ! -f "$filepath" ]; then
        log "$filepath does not exist, skipping"
        continue
    fi
    make_mutable $filepath
    if [ $ROOTLESS -eq 1 ]; then
        file_size=$(du -sk "$filepath" | cut -f1)
        if [ "$file_size" -gt "$MAX_COPY_SIZE" ]; then # if this somehow happens, we have bigger things to worry about
            log "$filepath is too large to be patched, skipping"
            continue
        fi
        if ! setup_bind_mount "$filepath" > /dev/null; then
            log "Could not bind mount $filepath, skipping"
            continue
        fi
    fi
    log "$($patch_bin "$filepath")"
    make_immutable $filepath
done