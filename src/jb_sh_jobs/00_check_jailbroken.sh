if [ $RUN_MODE -eq 0 ] && [ $JAILBROKEN -eq 1 ]; then
    if [ $JB_SH_DEBUG -eq 1 ]; then
        log "Device already jailbroken - exiting."
    fi
    exit
fi