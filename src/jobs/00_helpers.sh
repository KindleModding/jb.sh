#!/bin/sh

###
# Define logging function
###

LOG_TO_FILE=0
if [ ! -f "/mnt/us/jb.sh.log" ] ; then
    LOG_TO_FILE=1
fi

JAILBROKEN=0
if [ -f "/etc/upstart/kmc.conf" ] ; then
    JAILBROKEN=1
fi

ARCH="armel"
# Check if the Kindle is ARMHF or ARMEL
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    ARCH="armhf"
fi


POS=1
log() {
    if [ $LOG_TO_FILE -eq 1 ]; then
        echo "${1}" >> /mnt/us/jb.sh.log
    fi
    if [ $JAILBROKEN -eq 0 ]; then
        eips 0 $POS "${1}"
    fi
    echo "${1}"
    f_log "I" "JB.SH" "" "${1}"
    POS=$((POS+1))
}

###
# Helper functions
###
make_mutable() {
    local my_path="${1}"
    # NOTE: Can't do that on symlinks, hence the hoop-jumping...
    if [ -d "${my_path}" ] ; then
        find "${my_path}" -type d -exec chattr -i '{}' \;
        find "${my_path}" -type f -exec chattr -i '{}' \;
    elif [ -f "${my_path}" ] ; then
        chattr -i "${my_path}"
    fi
}

make_immutable() {
    local my_path="${1}"
    if [ -d "${my_path}" ] ; then
        find "${my_path}" -type d -exec chattr +i '{}' \;
        find "${my_path}" -type f -exec chattr +i '{}' \;
    elif [ -f "${my_path}" ] ; then
        chattr +i "${my_path}"
    fi
}