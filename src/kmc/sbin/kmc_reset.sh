#!/bin/sh

# Find which chattr to use
OLD_CHATTR="/bin/chattr"
NEW_CHATTR="/bin/chattr.e2fsprogs" # KT6 5.18.1.5+ and PW6, KS, & KS2 5.18.5+
if [ -f "${OLD_CHATTR}" ]; then
    CHATTR="${OLD_CHATTR}"
elif [ -f "${NEW_CHATTR}" ]; then
    CHATTR="${NEW_CHATTR}"
else
    # We couldn't find one, show an error, and pretend it's the old one I guess
    log "Error: Could not find chattr command. This is bad."
    CHATTR="${OLD_CHATTR}" # won't be found, but better than nothing?
fi

###
# Helper functions
###
make_mutable() {
    local my_path="${1}"
    # NOTE: Can't do that on symlinks, hence the hoop-jumping...
    if [ -d "${my_path}" ] ; then
        find "${my_path}" -type d -exec ${CHATTR} -i '{}' \; 2>/dev/null || true
        find "${my_path}" -type f -exec ${CHATTR} -i '{}' \; 2>/dev/null || true
    elif [ -f "${my_path}" ] ; then
        ${CHATTR} -i "${my_path}" 2>/dev/null || true
    fi
}

mntroot rw 2>/dev/null || /bin/mount -o remount,rw / 2>/dev/null || true

if [ ! -e /sbin/sfdisk ] && [ -x /usr/sbin/sfdisk ]; then
    ln -sf /usr/sbin/sfdisk /sbin/sfdisk 2>/dev/null || true
fi

if [ -f "/usr/bin/otaupd.bck" ] ; then
    make_mutable /usr/bin/otaupd
    mv /usr/bin/otaupd.bck /usr/bin/otaupd
fi

if [ -f "/usr/bin/otav3.bck" ] ; then
    make_mutable /usr/bin/otav3
    mv /usr/bin/otav3.bck /usr/bin/otav3
fi

# Disarm v4 untether and mark /var/base-local for clean restoration on factory reset
make_mutable /etc/upstart/untether-rearm.conf
make_mutable /var/local/xorg.conf
if [ -s /var/local/xm/xorg.conf.stock ]; then
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
elif [ -s /var/local/kmc/xorg.conf.stock ]; then
    cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
fi
/var/local/xm/untether-disarm.sh 2>/dev/null || true
rm -f /etc/upstart/untether-rearm.conf /var/local/xm/xm.so /var/local/kmc/xm.so /var/local/kmc/xm/xm.so 2>/dev/null || true
if [ -s /var/local/xm/xorg.conf.stock ]; then
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
elif [ -s /var/local/kmc/xorg.conf.stock ]; then
    cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
fi
make_mutable /var/local/kmc
make_mutable /var/local/mkk
make_mutable /var/base-local/.root_ovl
if [ -d /var/base-local ]; then
    touch /var/base-local/RESTORE_VAR_LOCAL 2>/dev/null || true
    [ -d /var/base-local/.root_ovl ] && touch /var/base-local/.root_ovl/.reset_on_next_boot 2>/dev/null || true
fi
initctl reload-configuration >/dev/null 2>&1 || true
sync

# No need to RO since now it's freset's turn to do things