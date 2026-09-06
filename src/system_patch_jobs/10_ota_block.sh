#!/bin/sh

log "Stopping OTA"

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

ota_block_file_message="DO NOT REMOVE - OTA Update Blocker"
ota_block_file_message_hash="aa3b1f5cc508e957f26de725c4b8a46a"

if [ -d /mnt/userstore ]; then
    ota_block_file="/mnt/userstore/update.bin.tmp.partial"
else
    ota_block_file="/mnt/us/update.bin.tmp.partial"
fi

check_ota_block_file() {
    if [ ! -f "${ota_block_file}" ]; then
        return 1 # File doesn't exist
    elif ! check_immutable "${ota_block_file}"; then
        return 2 # File isn't immutable (probably evil)
    elif [ $(md5sum "${ota_block_file}" | cut -d' ' -f1) != "${ota_block_file_message_hash}" ]; then
        return 3 # Invalid hash (probably evil)
    else
        return 0 # Everything is chill
    fi
}

write_ota_block_file() {
    if [ ${ota_block_file} == "/mnt/us/update.bin.tmp.partial" ]; then # can't use chattr on a FUSE mount, so we have to do some huge trolling
        log "Writing OTA block file to ${ota_block_file}"
        check_ota_block_file
        post_write_ota_block_status=$?
        if [ $post_write_ota_block_status -eq 3 ]; then
            log "Update file detected, removing"
            rm -f "${ota_block_file}"
        fi
        touch "${ota_block_file}"
        make_immutable "/var/local/kmc/block_ota"
        if ! cut -d' ' -f4,5 /proc/self/mountinfo | grep -xq "/var/local/kmc/block_ota /mnt/us/update.bin.tmp.partial"; then
            /bin/mount -o bind "/var/local/kmc/block_ota" "/mnt/us/update.bin.tmp.partial" # https://youtu.be/k0X71gtCBh8?t=14
        fi
    else
        log "Writing OTA block file to ${ota_block_file}"
        if [ -f "${ota_block_file}" ]; then
            # Make existing file mutable
            make_mutable "${ota_block_file}"
        fi
        echo -n "${ota_block_file_message}" > "${ota_block_file}"
        make_immutable "${ota_block_file}"
    fi
}

log "Stopping OTA"

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

log "Blocking OTA"

if check_ota_block_file; then
    logmsg I setup_ota_blocking "" "OTA Blocking already in place"
else
    write_ota_block_file # Install the blocking file
    # Check our work
    check_ota_block_file
    post_write_ota_block_status=$?
    if [ $post_write_ota_block_status -eq 0 ]; then
        log "OTA blocking file written successfully"
    else
        log "WRITING OTA BLOCK FILE FAILED SOMEHOW. YOUR JAILBREAK MAY BE AT RISK"
    fi
fi
