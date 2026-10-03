#!/bin/sh
if [ ! -f "/mnt/us/ACCESS_HELPAPP" ]; then # sadly, this is probably the simplest way to not take away access to the help menus from a user
    MANPATCH=1 sh /var/local/kmc/system_patches/run_patch.sh &
fi

# exec so the shell process is replaced with mesquite
exec /usr/bin/mesquite -l com.lab126.helpapp -c file:///var/local/mesquite/help/ "$@"