if [ -n "${JB_HEADER+x}" ]; then
    log "Powered by jb.sh - created by Hackerdude"
    log "$JB_SH_VERSION"
    printf "$JB_HEADER" | while IFS= read -r line ; do log "$line"; done
    POS=$((POS + $(echo $JB_HEADER | grep -c \n) + 1))
else
    log "Monolithic jb.sh"
    log "$JB_SH_VERSION"
    log "Created by Hackerdude"
    log "https://donate.hackerdude.tech"
    log ""
    log "  \"If you wish to make an apple pie from scratch"
    log "  you must first invent the universe\""
    log " Carl Sagan"
fi

log ""
log "P:$RUN_MODE:$JAILBROKEN:$ARCH"
log ""