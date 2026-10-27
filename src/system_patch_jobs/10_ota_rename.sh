#!/bin/sh

log "Stopping OTA"

destroy_otas

log "Renaming OTA and installing no-op sleep stubs"

if [ -f "/usr/bin/otaupd" ] && [ ! -f "/usr/bin/otaupd.bck" ] && ! grep -q 'sleep 86400' /usr/bin/otaupd 2>/dev/null ; then
    log "Renaming otaupd"
    make_mutable /usr/bin/otaupd
    mv /usr/bin/otaupd /usr/bin/otaupd.bck
fi
make_mutable /usr/bin/otaupd 2>/dev/null || true
rm -f /usr/bin/otaupd 2>/dev/null || true
printf '#!/bin/sh\nexec /bin/sleep 86400\n' > /usr/bin/otaupd
chown root:root /usr/bin/otaupd 2>/dev/null || true
chmod 0755 /usr/bin/otaupd

if [ -f "/usr/bin/otav3" ] && [ ! -f "/usr/bin/otav3.bck" ] && ! grep -q 'sleep 86400' /usr/bin/otav3 2>/dev/null ; then
    log "Renaming otav3"
    make_mutable /usr/bin/otav3
    mv /usr/bin/otav3 /usr/bin/otav3.bck
fi
make_mutable /usr/bin/otav3 2>/dev/null || true
rm -f /usr/bin/otav3 2>/dev/null || true
printf '#!/bin/sh\nexec /bin/sleep 86400\n' > /usr/bin/otav3
chown root:root /usr/bin/otav3 2>/dev/null || true
chmod 0755 /usr/bin/otav3

destroy_otas