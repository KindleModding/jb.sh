# In all scripts
if [ -n "${JB_HEADER+x}" ]; then
    log "Powered by jb.sh - created by Hackerdude"
    log "$JB_SH_VERSION"
    printf "$JB_HEADER" | while IFS= read -r line ; do log "$line"; done
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
log "J:$RUN_MODE:$JAILBROKEN:$ARCH"
log ""

if [ $JB_SH_DEBUG -eq 1 ]; then
log "Running in DEBUG mode"
log "Starting telnet..."
ip_addr=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

iptables -A INPUT -p tcp --dport 23 -j ACCEPT
telnetd -l /bin/sh -p 23

log "Telnet Started On: $ip_addr : 23"
fi