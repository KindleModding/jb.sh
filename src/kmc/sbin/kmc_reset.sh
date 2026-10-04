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
        find "${my_path}" -type d -exec ${CHATTR} -i '{}' \;
        find "${my_path}" -type f -exec ${CHATTR} -i '{}' \;
    elif [ -f "${my_path}" ] ; then
        ${CHATTR} -i "${my_path}"
    fi
}

mntroot rw

if [ -f "/usr/bin/otaupd.bck" ] ; then
    make_mutable /usr/bin/otaupd
    mv /usr/bin/otaupd.bck /usr/bin/otaupd
fi

if [ -f "/usr/bin/otav3.bck" ] ; then
    make_mutable /usr/bin/otav3
    mv /usr/bin/otav3.bck /usr/bin/otav3
fi

# No need to RO since now it's freset's turn to do things