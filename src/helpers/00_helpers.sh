#!/bin/sh

###
# Defines
###
JB_VERSION="v1.0.0"

###
# Define logging function
###

JB_SH_DEBUG=0
if [ -f "/mnt/us/jb.sh.debug" ] ; then
    JB_SH_DEBUG=1
fi

# RUN_MODE tells the script what mode it's running in
# 0 - Manually run
# 1 - Run automatically
if [ ! -n "${RUN_MODE+x}" ]; then
# If run_mode isn't specified we assume it was done automatically
RUN_MODE=1
fi

# If already jailbroken then we know this is an update
JAILBROKEN=0
if [ -d "/var/local/kmc" ] ; then
    JAILBROKEN=1
fi

ARCH="armel"
# Check if the Kindle is ARMHF or ARMEL
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    ARCH="armhf"
fi


POS=1
log() {
    if [ $JB_SH_DEBUG -eq 1 ]; then
        echo "${1}" >> /mnt/us/jb.sh.log
    fi

    if command -v eips_v2 >/dev/null 2>&1; then
        eips_v2 text "${1}" --top $(( POS * 24 ))
    else
        eips 0 $POS "${1}"
    fi
    
    echo "${1}"
    POS=$((POS+1))
}

# Find which chattr to use
OLD_CHATTR="/bin/chattr"
NEW_CHATTR="/bin/chattr.e2fsprogs" # KT6 5.18.1.5+ and PW6, KS, & KS2 5.18.5+
if [ -f "${OLD_CHATTR}" ]; then
    CHATTR="${OLD_CHATTR}"
elif [ -f "${NEW_CHATTR}" ]; then
    CHATTR="${NEW_CHATTR}"
else
    # We couldn't find one, show an error, and pretend it's the old one I guess
    log "Error: Could not find chattr command! This is bad!"
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

make_immutable() {
    local my_path="${1}"
    if [ -d "${my_path}" ] ; then
        find "${my_path}" -type d -exec ${CHATTR} +i '{}' \;
        find "${my_path}" -type f -exec ${CHATTR} +i '{}' \;
    elif [ -f "${my_path}" ] ; then
        ${CHATTR} +i "${my_path}"
    fi
}