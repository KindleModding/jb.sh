#!/bin/sh

###
# Defines
###
JB_SH_VERSION="v2.0.2"

if [ ! -n "${JB_HEADER+x}" ] && [ -f "/var/local/jailbreak.txt" ]; then
    JB_HEADER=$(cat /var/local/jailbreak.txt)
fi

if [ ! -n "${JB_SH_DEBUG+x}" ]; then
# If run_mode isn't specified we assume it was done automatically on startup or smth (ie: UJ)
JB_SH_DEBUG=0
fi

if [ -f "/mnt/us/jb.sh.debug" ]; then
    JB_SH_DEBUG=1
fi

# RUN_MODE tells the script what mode it's running in
# 0 - Run automatically on startup
# 1 - Manually run (will ignore jailbroken state and forces run)
# 2 - Run as part of an update (will ignore jailbroken state and forces run)
if [ ! -n "${RUN_MODE+x}" ]; then
# If run_mode isn't specified we assume it was done automatically on startup or smth (ie: UJ)
RUN_MODE=0
fi

if [ -f "/mnt/us/jb.sh.runmode0" ]; then
    RUN_MODE=0
    rm /mnt/us/jb.sh.runmode0
fi
if [ -f "/mnt/us/jb.sh.runmode1" ]; then
    RUN_MODE=1
    rm /mnt/us/jb.sh.runmode1
fi
if [ -f "/mnt/us/jb.sh.runmode2" ]; then
    RUN_MODE=2
    rm /mnt/us/jb.sh.runmode2
fi

# If already jailbroken then we know this is an update
if [ ! -n "${JAILBROKEN+x}" ]; then
    JAILBROKEN=0
    if [ -d "/var/local/kmc/bin" ] ; then
        JAILBROKEN=1
    fi
fi

PLATFORM="kindlepw2"
# Check if the Kindle is kindlehf or kindlepw2
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    PLATFORM="kindlehf"
fi

# Check if Kindle is rootless (rootfs is signed and RO)
ROOTLESS=0
if cat /proc/cmdline | grep androidboot.veritymode; then
    ROOTLESS=1
fi

if [ -z "$MANPATCH" ]; then
    MANPATCH=0 # passed by rootless_menu.sh when 1
fi

POS=1
log() {
    if [ $JB_SH_DEBUG -eq 1 ]; then
        printf "${1}\n" >> /mnt/us/jb.sh.log
    fi
    printf "${1}\n"

    POS=$((POS+1)) # Increment first in case there's an error
    if command -v eips_v2 >/dev/null 2>&1; then
        eips_v2 text "${1}" --top $(( (POS-1) * 24 ))
    else
        eips 0 $((POS-1)) "${1}"
    fi
    
    logger "I JB_SH ${RUN_MODE}_${JAILBROKEN}_${ROOTLESS}:: ${1}"
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

make_immutable() {
    local my_path="${1}"
    if [ -d "${my_path}" ] ; then
        find "${my_path}" -type d -exec ${CHATTR} +i '{}' \;
        find "${my_path}" -type f -exec ${CHATTR} +i '{}' \;
    elif [ -f "${my_path}" ] ; then
        ${CHATTR} +i "${my_path}"
    fi
}

# Returns 0 (true) if immutable bit is set, 1 (false) if not (or if file doesn't exist)
check_immutable() {
    lsattr.e2fsprogs "$1" | cut -d' ' -f1 | grep -q 'i'
}

destroy_otas() {
    stop ota-update
    stop otaupd
    stop otav3

    # Kill them asap
    killall otaupd -s SIGKILL s
    killall otav3 -s SIGKILL s

    # Thanks scam.net for new paths
    rm -rf /mnt/us/*.tmp.partial
    rm -rf /mnt/us/*.bin
    rm -rf /mnt/us/*.bin.tmp
    rm -rf /mnt/base-us/*.tmp.partial
    rm -rf /mnt/base-us/*.bin
    rm -rf /mnt/base-us/*.bin.tmp
    rm -rf /mnt/userstore/*.tmp.partial
    rm -rf /mnt/userstore/*.bin
    rm -rf /mnt/userstore/*.bin.tmp
}

# Setup Bind Mount - sets up a bind mount for a file/directory (likely on rootfs)
# by making a temporary file/directory in EARLYBIRD_BINDS_PATH at a corresponding path
# Outputs the path to the temporary file/directory
# Credit to scam.net for this function

MAX_COPY_SIZE=5192 # Max size (in KB) to copy to /var/local/kmc/binds for bind mounts
setup_bind_mount() {
    local overridden_path="$(realpath "${1}")"
    local bind_path="/var/local/kmc/binds${overridden_path}"
    local bind_parent_path="$(dirname "${bind_path}")"
    # if it doesn't already exist, we need to make it
    if [ ! -e "${bind_path}" ]; then
        mkdir -p "${bind_parent_path}"
        # straight up copy everything, will work for both dirs and files
        cp -a "${overridden_path}" "${bind_parent_path}"
    fi
    # Check to make sure we aren't already mounted. Yes this is sinful as fuck. I'm sorry.
    if cut -d' ' -f5 /proc/self/mountinfo | grep -xq "${overridden_path}"; then
        umount "${overridden_path}" # Necessary because of potential stale mounts when MANPATCHning jb.sh
    fi
    mount -o bind "${bind_path}" "${overridden_path}"
    echo "${bind_path}"
}