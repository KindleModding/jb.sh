#!/bin/sh

log "Copying dispatch (logThis) script"
make_mutable "/usr/bin/logThis.sh"
rm -rf "/usr/bin/logThis.sh"
cp -f "/var/local/kmc/system_patches/dispatch.sh" "/usr/bin/logThis.sh"
chmod 0755 "/usr/bin/logThis.sh"
make_immutable "/usr/bin/logThis.sh"