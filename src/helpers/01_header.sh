# In all scripts
log "Monolithic jb.sh"
log "Created by HackerDude"
log "$JB_VERSION"
log ""
log "  \"If you wish to make an apple pie from scratch"
log "  you must first invent the universe\""
log " Carl Sagan"
log ""
log "Jailbroken - $JAILBROKEN"
log "Arch - $ARCH"
log ""
log "Starting telnet..."
ip_addr=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

iptables -A INPUT -p tcp --dport 23 -j ACCEPT
telnetd -l /bin/sh -p 23

log "Telnet Started On: $ip_addr : 23"