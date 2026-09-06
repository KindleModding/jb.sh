#!/bin/sh

log "Stopping OTA"

stop ota-update
stop otaupd
stop otav3

# Kill them asap
killall otaupd -s SIGKILL s
killall otav3 -s SIGKILL s

if [ $ROOTLESS -eq 1 ]; then
    ota_block_file_message="DO NOT REMOVE - OTA Update Blocker"
    ota_block_file_message_hash="aa3b1f5cc508e957f26de725c4b8a46a"

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
        logmsg "Writing OTA block file to ${ota_block_file}"
        if [ -f "${ota_block_file}" ]; then
            # Make existing file mutable
            make_mutable "${ota_block_file}"
        fi
        echo -n "${ota_block_file_message}" > "${ota_block_file}"
        make_immutable "${ota_block_file}"
    }

    log "Stopping OTA"

    stop ota-update
    stop otaupd
    stop otav3

    # Kill them asap
    killall otaupd -s SIGKILL s
    killall otav3 -s SIGKILL s

    log "Renaming OTA"

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
fi

log "Renaming OTA"

if [ -f "/usr/bin/otaupd" ] ; then
    log "Renaming otaupd"
    make_mutable /usr/bin/otaupd
    mv /usr/bin/otaupd /usr/bin/otaupd.bck
fi

if [ -f "/usr/bin/otav3" ] ; then
    log "Renaming otav3"
    make_mutable /usr/bin/otav3
    mv /usr/bin/otav3 /usr/bin/otav3.bck
fi