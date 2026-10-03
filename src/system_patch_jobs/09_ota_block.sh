#!/bin/sh
# Credit to scam.net for a large portion of this file
log "Stopping OTA"

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

# If the binaries were renamed with the old method, restore them.
if [ $ROOTLESS -eq 0 ]; then
    if [ -f /usr/bin/otaupd.bck ]; then
        log "Restoring previously renamed OTA binaries"
        make_mutable /usr/bin/otaupd.bck
        mv /usr/bin/otaupd.bck /usr/bin/otaupd
    fi

    if [ -f /usr/bin/otav3.bck ]; then
        make_mutable /usr/bin/otav3.bck
        mv /usr/bin/otav3.bck /usr/bin/otav3
    fi
fi

ota_block_file_message="DO NOT REMOVE - OTA Update Blocker"
ota_block_file_message_hash="aa3b1f5cc508e957f26de725c4b8a46a"

if [ -d /mnt/userstore ]; then
    ota_block_file="/mnt/userstore/update.bin.tmp.partial"
else
    ota_block_file="/mnt/us/update.bin.tmp.partial"
fi

check_mount() {
    [ "${ota_block_file}" != "/mnt/us/update.bin.tmp.partial" ] && return 0 # Return 0 if this is somehow called while the OTA block file is mntus

    if ! cut -d' ' -f5 /proc/self/mountinfo | grep -xq "/mnt/us/update.bin.tmp.partial"; then
        return 1
    else
        return 0
    fi
}

check_ota_block_file() {
    if [ ! -f "${ota_block_file}" ]; then
        return 1
    fi  # File disappeared somehow, bad.
    if [ "${ota_block_file}" == "/mnt/us/update.bin.tmp.partial" ]; then # We have to check each file in different ways, because you can't use lsattr on a fuse mount.
        check_mount || return 2 # Not mounted, bad.
    elif [ "${ota_block_file}" == "/mnt/userstore/update.bin.tmp.partial" ]; then
        check_immutable "${ota_block_file}" || return 2 # File mutable, bad.
    fi
    [ "$(md5sum "${ota_block_file}" | cut -d' ' -f1)" != "${ota_block_file_message_hash}" ] && return 3 # If the other two didn't return anything bad, run this.
    return 0
}

write_ota_block_file() {
    if [ "${ota_block_file}" == "/mnt/us/update.bin.tmp.partial" ]; then
        log "Writing OTA block file to ${ota_block_file}"
        if [ ! "$(md5sum "${ota_block_file}" | cut -d' ' -f1)" != "${ota_block_file_message_hash}" ]; then # all we really care about rn is the hash
            log "Update file detected, removing"
            rm -f "${ota_block_file}"
        fi
        touch "${ota_block_file}"
        make_immutable "/var/local/kmc/block_ota"
        /bin/umount "${ota_block_file}" # we HAVE to do this in case we're unpacking the new kmc/block_ota over an OLD kmc/block_ota, in which case the bind mount will resolve to an empty file
        /bin/mount -o bind "/var/local/kmc/block_ota" "/mnt/us/update.bin.tmp.partial"
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

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

log "Blocking OTA"

if check_ota_block_file; then
    log "OTA Blocking already in place"
else
    write_ota_block_file # Install the blocking file
    # Check our work
    check_ota_block_file
    post_write_ota_block_status=$?
    if [ $post_write_ota_block_status -eq 0 ]; then
        log "OTA blocking file written successfully"
    else
        log "WRITING OTA BLOCK FILE FAILED WITH ERROR CODE ${post_write_ota_block_status}. YOUR JAILBREAK MAY BE AT RISK"
    fi
fi
