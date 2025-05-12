#!/bin/sh
#
# WinterBreak Jailbreak Script
# Based on the bridge script from the 1.16.N hotfix package
# Special thanks to Marek, Katadelos and NiLuJe
#
# $Id: jb.sh ????? 2023-11-19 08:12:38Z HackerDude $
#
##



set +e # If boot is halted stuff seriously goes wrong (actually we don't need this anymore but I'm keeping it)


###
# Define logging function
###
POS=1
wb_log() {
  echo "${1}" >> /mnt/us/winterbreak.log
  eips 0 $POS "${1}"
  echo "${1}"
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




###
# Actual JB from here
###
wb_log "************ JB.sh ************"
wb_log "*    Created by HackerDude    *"
wb_log "********************** 2.0.0 *"
wb_log ""
wb_log "Like what you see? Donate to my Ko-Fi"
wb_log "to help support these projects:"
wb_log "https://ko-fi.com/hackerdude"
wb_log ""
wb_log "Thanks to Marek, Katadelos and NiLuJe for their help"
wb_log "creating this script"
wb_log ""
wb_log "After all, all devices have their dangers."
wb_log "The discovery of speech introduced communication - and lies."
wb_log "- Isaac Asimov"
wb_log ""
wb_log ""


###
# Main key install functions
###
install_touch_update_key()
{
        wb_log "install_touch_update_key - Copying the jailbreak updater key"
        make_mutable "/etc/uks/pubdevkey01.pem"
        rm -rf "/etc/uks/pubdevkey01.pem"
        cat > "/etc/uks/pubdevkey01.pem" << EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF
        # Harmonize permissions
        chown root:root "/etc/uks/pubdevkey01.pem"
        chmod 0644 "/etc/uks/pubdevkey01.pem"
        make_immutable "/etc/uks/pubdevkey01.pem"
}

install_touch_update_key_squash()
{
    wb_log "install_touch_update_key_squash - Copying the jailbreak updater keystore"
    make_mutable "/etc/uks.sqsh"
    local my_loop="$(grep ' /etc/uks ' /proc/mounts | cut -f1 -d' ')"
    umount "${my_loop}"
    losetup -d "${my_loop}"
    cp --verbose -f "/mnt/us/patchedUks.sqsh" "/etc/uks.sqsh"
    mount -o loop="${my_loop}",nodiratime,noatime -t squashfs "/etc/uks.sqsh" "/etc/uks"
    chown root:root "/etc/uks.sqsh"
    chmod 0644 "/etc/uks.sqsh"
    #make_immutable "/etc/uks.sqsh" # This breaks mounting on 12th gen (no, really)
}

# The real fun starts here
mntroot rw

# First we eradicate any partially downloaded update files (stops update mid-JB)
rm -f /mnt/us/*.partial

# Disable OTA if it isn't already
if [ ! -f "/usr/bin/otaupd.bck" ] ; then
  killall otaupd
  mv /usr/bin/otaupd /usr/bin/otaupd.bck
  wb_log "otaupd renamed"
fi

if [ ! -f "/usr/bin/otav3.bck" ] ; then
  killall otav3
  mv /usr/bin/otav3 /usr/bin/otav3.bck
  wb_log "otav3 renamed"
fi

# Install update key in folder
install_touch_update_key
# Verify key installation
if [ -f "/etc/uks/pubdevkey01.pem" ] ; then
wb_log "Developer keys installed successfully (Standard Method)! (pubdevkey01.pem)"
else
  wb_log "ERR - Could not install pubdevkey01.pem (Standard Method)"
fi

# Check if we need to do something with the OTA SQSH keystore
if [ -f "/etc/uks.sqsh" ] && [ -f "/mnt/us/patchedUks.sqsh" ] ; then
  install_touch_update_key_squash

  # Verify key installation
  if [ "$(md5sum "${ROOT}/etc/uks.sqsh" | awk '{ print $1; }')" ==  "$(md5sum "${ROOT}/mnt/us/patchedUks.sqsh" | awk '{ print $1; }')" ] ; then
    wb_log "Developer keys installed successfully! (uks.sqsh)"
    wb_log "$(ls /etc/uks)"
  else
    wb_log "ERR - Could not install uks.sqsh"
    wb_log "$(whoami)"
    wb_log "$(md5sum "/mnt/us/patchedUks.sqsh" | awk '{ print $1; }')"
    wb_log "$(md5sum "/etc/uks.sqsh" | awk '{ print $1; }')"
    wb_log "$(md5sum "${ROOT}/etc/uks.sqsh" | awk '{ print $1; }')"
  fi
fi

# Make sure we can use UYK for OTA packages on FW >= 5.12.x
make_mutable "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
rm -rf "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
touch "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
make_immutable "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"

if [ -f "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC" ] ; then
    wb_log "Enabled developer flag"
else
    wb_log "Developer flag install FAIL"
fi


touch "/MNTUS_EXEC"
make_immutable "/MNTUS_EXEC"

if [ -f "/MNTUS_EXEC" ] ; then
    wb_log "Enabled mntus exec flag"
else
    wb_log "mntus exec flag install FAIL"
fi

# Bye
mntroot ro

wb_log "                                      "
wb_log "**************************************"
wb_log "*** Finished installing jailbreak! ***"
wb_log "***                                ***"
wb_log "***   Please Install HOTFIX now    ***"
wb_log "**************************************"
wb_log "                                      "
wb_log "                                      "