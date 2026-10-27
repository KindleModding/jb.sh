#!/bin/sh
# /var/local/kmc/run_hotfix.sh — Unified ROOTLESS=0 v4 Hotfix & Untether Runner
# Escalates to root via gandalf (su) if invoked as framework from the Kindle UI,
# installs/updates /var/local/xm/{xm.so,stage1_pivot.sh,boot.sh,untether-arm.sh,untether-disarm.sh}
# when androidboot.veritymode is detected (or /var/local/xm/xm.so is installed),
# runs /var/local/xm/stage1_pivot.sh immediately to pivot / onto writable overlayfs
# and strip androidboot.veritymode from /proc/cmdline, re-evaluates ROOTLESS=0,
# and runs /var/local/kmc/system_patches/patch_system.sh in ROOTLESS=0 mode.

for _fd in /proc/$$/fd/*; do
    _fd_num="${_fd##*/}"
    if [ "$_fd_num" -gt 2 ] 2>/dev/null; then
        eval "exec ${_fd_num}>&-" 2>/dev/null || true
    fi
done

ARCH="kindlepw2"
if [ -f /lib/ld-linux-armhf.so.3 ]; then
    ARCH="kindlehf"
fi

# Escalate to root via setuid gandalf (su) when invoked as non-root
if [ "$(id -u)" -ne 0 ]; then
    if [ -x "/var/local/kmc/${ARCH}/bin/su" ]; then
        exec "/var/local/kmc/${ARCH}/bin/su" -c "sh /var/local/kmc/run_hotfix.sh"
    elif [ -x "/var/local/mkk/su" ]; then
        exec /var/local/mkk/su -c "sh /var/local/kmc/run_hotfix.sh"
    else
        echo "run_hotfix: error: su binary not found" >&2
        exit 1
    fi
fi

CHATTR="/bin/chattr.e2fsprogs"
[ -x "$CHATTR" ] || CHATTR="/bin/chattr"
KMC="/var/local/kmc"
XM="/var/local/xm"
FMT_FILE="$XM/.untether-fmt"
TRIES_FILE="/var/base-local/.ovl_boot_tries"

ROOTLESS=0
if grep -q "androidboot.veritymode" /proc/cmdline /dev/.ovl/old_root/proc/cmdline /dev/.ovl/lower/proc/cmdline 2>/dev/null || \
   [ -b /dev/dm-0 ]; then
    ROOTLESS=1
fi

HAS_UNTETHER=0
if [ "$ROOTLESS" -eq 1 ] || [ -f "$XM/xm.so" ] || [ -f "$KMC/xm.so" ] || \
   [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" = "overlay" ]; then
    HAS_UNTETHER=1
fi

# Classic pre-2025 non-verity Kindle path
if [ "$HAS_UNTETHER" -eq 0 ]; then
    TMP_JB="$(curl -fsSL --connect-timeout 5 https://kindlemodding.org/jb.sh 2>/dev/null || true)"
    if [ -n "$TMP_JB" ]; then
        printf '%s\n' "$TMP_JB" | RUN_MODE=1 sh || RUN_MODE=1 sh /var/local/kmc/system_patches/patch_system.sh
    else
        RUN_MODE=1 sh /var/local/kmc/system_patches/patch_system.sh
    fi
    exit $?
fi

# --- v4 ROOTLESS=0 Pivot & Untether Setup for dm-verity Kindles ---------------
"$CHATTR" -i "$KMC" 2>/dev/null || true
find "$KMC" -maxdepth 3 \( -type d -o -type f \) -exec "$CHATTR" -i '{}' \; 2>/dev/null || true
if [ -d /var/local/mkk ]; then
    "$CHATTR" -i /var/local/mkk 2>/dev/null || true
    find /var/local/mkk -maxdepth 2 \( -type d -o -type f \) -exec "$CHATTR" -i '{}' \; 2>/dev/null || true
fi
mkdir -p "$XM" "$KMC" /var/local/mkk

POS=1
hf_log() {
    echo "hotfix: $1" >> "$KMC/hotfix.log" 2>/dev/null
    echo "hotfix: $1"
    POS=$((POS + 1))
    if [ -x "$KMC/${ARCH}/bin/fbink" ]; then
        "$KMC/${ARCH}/bin/fbink" -y "$POS" "Hotfix: $1" >/dev/null 2>&1 || true
    elif command -v eips_v2 >/dev/null 2>&1; then
        eips_v2 text "Hotfix: $1" --top $(( (POS - 1) * 24 )) >/dev/null 2>&1 || true
    elif command -v eips >/dev/null 2>&1; then
        eips 0 $((POS - 1)) "Hotfix: $1" >/dev/null 2>&1 || true
    fi
    logger "I KMC_HOTFIX ROOTLESS0_V4:: $1" 2>/dev/null || true
}

hf_log "Installing v4 ROOTLESS=0 untether & pivoting rootfs..."

# 1. Ensure KMC & MKK links
if [ -d "$KMC/$ARCH/bin" ]; then
    rm -rf "$KMC/bin" "$KMC/lib" 2>/dev/null || true
    ln -sfn "$KMC/$ARCH/bin" "$KMC/bin"
    ln -sfn "$KMC/$ARCH/lib" "$KMC/lib"
    ln -sf "$KMC/$ARCH/bin/gandalf" "$KMC/$ARCH/bin/su"
    ln -sf "$KMC/bin/gandalf" /var/local/mkk/gandalf
    ln -sf /var/local/mkk/gandalf /var/local/mkk/su
fi

# 2. Save clean stock /var/local/xorg.conf baseline and install /var/local/xm/{xm.so,stage1_pivot.sh,boot.sh,untether-arm.sh,untether-disarm.sh}
if [ -s /var/local/xorg.conf ] && ! grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; then
    cp -f /var/local/xorg.conf "$XM/xorg.conf.stock" 2>/dev/null || true
    cp -f /var/local/xorg.conf "$KMC/xorg.conf.stock" 2>/dev/null || true
elif [ -s /var/local/xorg.conf ] && { [ ! -s "$XM/xorg.conf.stock" ] || grep -q 'xm\.so' "$XM/xorg.conf.stock" 2>/dev/null; }; then
    sed -e 's/\(Option[[:space:]]*"FormatEPDC"[[:space:]]*"[^"]*"\).*/\1/' \
        /var/local/xorg.conf > "$XM/xorg.conf.stock" 2>/dev/null || true
    cp -f "$XM/xorg.conf.stock" "$KMC/xorg.conf.stock" 2>/dev/null || true
fi

for uf in xm.so stage1_pivot.sh boot.sh untether-arm.sh untether-disarm.sh; do
    if [ -f "$KMC/xm/$uf" ]; then
        cp -f "$KMC/xm/$uf" "$XM/$uf"
        cp -f "$KMC/xm/$uf" "$KMC/$uf" 2>/dev/null || true
        chmod 755 "$XM/$uf" "$KMC/$uf" "$KMC/xm/$uf" 2>/dev/null || true
    elif [ -f "$KMC/$uf" ]; then
        cp -f "$KMC/$uf" "$XM/$uf"
        chmod 755 "$XM/$uf" "$KMC/$uf" 2>/dev/null || true
    fi
done

# 3. Run /var/local/xm/stage1_pivot.sh immediately to pivot / onto writable overlayfs
#    and explicitly guarantee / is remounted rw (even if / was already overlay ro)
echo 0 > "$TRIES_FILE" 2>/dev/null || true
/bin/sh "$XM/stage1_pivot.sh"
echo 0 > "$TRIES_FILE" 2>/dev/null || true
for _rmnt in /dev/.ovl/old_root/bin/mount /dev/.ovl/lower/bin/mount /bin/mount; do
    if [ -x "$_rmnt" ]; then
        "$_rmnt" -n -o remount,bind,rw /dev/root / 2>/dev/null || true
        "$_rmnt" -n -t overlay -o remount,rw /dev/root / 2>/dev/null || true
        "$_rmnt" -n -o remount,rw / 2>/dev/null || true
        break
    fi
done
/usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
[ -e /bin/chattr ] || ln -sf /bin/chattr.e2fsprogs /bin/chattr 2>/dev/null || true
if [ ! -e /sbin/sfdisk ] && [ -x /usr/sbin/sfdisk ]; then
    ln -sf /usr/sbin/sfdisk /sbin/sfdisk 2>/dev/null || true
fi

# Re-evaluate ROOTLESS after stage1_pivot.sh strips androidboot.veritymode from /proc/cmdline
ROOTLESS=0
if grep -q "androidboot.veritymode" /proc/cmdline 2>/dev/null; then
    ROOTLESS=1
fi
hf_log "Pivoted rootfs (ROOTLESS=$ROOTLESS, fstype=$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null))"

# 4. Run patch_system.sh (01_mntroot.sh .. 11_reset_patch.sh) in ROOTLESS=0 mode
"$CHATTR" -i /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
             /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
             /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
             /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
             /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
             /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
if [ "$ROOTLESS" -eq 0 ]; then
    ROOTLESS=0 RUN_MODE=1 JAILBROKEN=1 sh /var/local/kmc/system_patches/patch_system.sh
fi

# 5. Ensure libfbink.so symlinks, /etc/upstart/untether-rearm.conf, /mnt/us exec, and appreg.db
/usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
"$CHATTR" -i /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
             /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
             /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
             /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
             /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
             /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
[ -f /usr/sbin/factory_reset ] && chmod 0755 /usr/sbin/factory_reset 2>/dev/null || true
if [ -f "$KMC/lib/libfbink.so" ]; then
    ln -sf "$KMC/lib/libfbink.so" /usr/lib/libfbink.so.1 2>/dev/null || true
    ln -sf "$KMC/lib/libfbink.so" /usr/lib/libfbink.so 2>/dev/null || true
fi
for _chroot_ul in /var/tmp/chroot/usr/lib /chroot/usr/lib; do
    if [ -d "$_chroot_ul" ] && awk -v m="$_chroot_ul" '$2 == m && $3 != "overlay" { found=1; exit } END { exit !found }' /proc/mounts 2>/dev/null; then
        umount -l "$_chroot_ul" 2>/dev/null || true
        mount --bind /usr/lib "$_chroot_ul" 2>/dev/null || true
        break
    fi
done
chown 0:0 / /bin /bin/mount /usr /usr/sbin /usr/sbin/mntroot \
          /etc /etc/uks /etc/uks/pubdevkey01.pem /etc/upstart /etc/upstart/kmc.conf \
          /usr/lib /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
          /opt /opt/amazon /opt/amazon/ebook /opt/amazon/ebook/lib /opt/amazon/ebook/lib/json_simple-1.1.jar \
          /usr/bin /usr/bin/logThis.sh /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
          /usr/sbin/factory_reset /usr/sbin/factory_reset.bck \
          /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
          /app /app/kpp_app_cmds.json /usr/share /usr/share/app /usr/share/app/kpp_sys_cmds.json 2>/dev/null || true
chmod 0755 / /bin /bin/mount /usr /usr/sbin /usr/sbin/mntroot \
           /etc /etc/uks /etc/upstart /usr/lib /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
           /opt /opt/amazon /opt/amazon/ebook /opt/amazon/ebook/lib \
           /usr/bin /usr/bin/logThis.sh /usr/bin/otaupd /usr/bin/otav3 /usr/sbin/factory_reset \
           /app /usr/share /usr/share/app 2>/dev/null || true
"$CHATTR" +i /etc/uks/pubdevkey01.pem /usr/lib/ccat/sh_integration_extractor.so \
             /usr/bin/logThis.sh /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC \
             /MNTUS_EXEC /etc/upstart/kmc.conf 2>/dev/null || true
"$CHATTR" -i /etc/upstart/untether-rearm.conf 2>/dev/null || true
cat > /etc/upstart/untether-rearm.conf <<'REARM_EOF'
description "Re-arm the untether dynconf hook before next boot"
start on stopping x
task
script
    if [ -f /var/local/xm/xm.so ] && [ ! -e /dev/.ovl_recovery_mode ]; then
        if [ -x /var/local/xm/untether-arm.sh ]; then
            /var/local/xm/untether-arm.sh
        elif [ -x /var/local/kmc/untether-arm.sh ]; then
            /var/local/kmc/untether-arm.sh
        fi
        touch /var/local/EPDCMODE_RESET_DONE
    fi
end script
REARM_EOF
chmod 0644 /etc/upstart/untether-rearm.conf 2>/dev/null || true
if [ -n "$(pidof KPPMainAppV2 KPPMainApp kppmainapp 2>/dev/null)" ]; then
    initctl reload-configuration >/dev/null 2>&1 || true
fi

if [ -f /var/local/appreg.db ] && command -v sqlite3 >/dev/null 2>&1; then
    if [ -s /var/local/appreg.db ] && [ ! -s /var/local/appreg.db.stock ]; then
        _appreg_ic="$(echo "PRAGMA busy_timeout = 5000; PRAGMA integrity_check;" | sqlite3 /var/local/appreg.db 2>/dev/null | tail -n 1)"
        if [ "$_appreg_ic" = "ok" ]; then
            cp -f /var/local/appreg.db /var/local/appreg.db.stock 2>/dev/null || true
            sync
        fi
    fi
    [ -f "$KMC/sql/appreg_register_hotfix.sql" ] && sqlite3 /var/local/appreg.db < "$KMC/sql/appreg_register_hotfix.sql" 2>/dev/null || true
    [ -f "$KMC/sql/appreg_register_emergency.sql" ] && sqlite3 /var/local/appreg.db < "$KMC/sql/appreg_register_emergency.sql" 2>/dev/null || true
fi

if grep -q " /mnt/us " /proc/mounts 2>/dev/null; then
    /bin/mount -i -o remount,exec /mnt/us 2>/dev/null || \
        /dev/.ovl/old_root/bin/mount -i -o remount,exec /mnt/us 2>/dev/null || \
        /bin/busybox.nosuid mount -o remount,exec /mnt/us 2>/dev/null || \
        mount -i -o remount,exec /mnt/us 2>/dev/null || true
    /bin/mount -i -o remount,exec /mnt/base-us 2>/dev/null || true
    [ -L /mnt/us/libkh ] && rm -f /mnt/us/libkh 2>/dev/null || true
    [ -L /mnt/us/libkh/bin ] && rm -f /mnt/us/libkh/bin 2>/dev/null || true
    [ -L /mnt/us/libkh/lib ] && rm -f /mnt/us/libkh/lib 2>/dev/null || true
    mkdir -p /mnt/us/libkh/bin /mnt/us/libkh/lib 2>/dev/null || true
    if [ ! -s /mnt/us/libkh/bin/fbink ]; then
        cp -f "$KMC/$ARCH/bin/fbink" /mnt/us/libkh/bin/fbink 2>/dev/null || \
            cp -f /var/local/kmc/bin/fbink /mnt/us/libkh/bin/fbink 2>/dev/null || true
        chmod 755 /mnt/us/libkh/bin/fbink 2>/dev/null || true
    fi
    if [ ! -s /mnt/us/libkh/lib/libfbink.so ]; then
        cp -f "$KMC/$ARCH/lib/libfbink.so" /mnt/us/libkh/lib/libfbink.so 2>/dev/null || \
            cp -f /var/local/kmc/lib/libfbink.so /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
        chmod 755 /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
    fi
    mkdir -p /mnt/us/documents 2>/dev/null || true
    [ -f "/mnt/us/documents/Run Hotfix.run_hotfix" ] || echo "Run Hotfix" > "/mnt/us/documents/Run Hotfix.run_hotfix" 2>/dev/null || true
fi

# 6. Arm winmgr.colorinverse.pref via /var/local/xm/untether-arm.sh and reset .ovl_boot_tries to 0
cp -f "$KMC/xm/xm.so" "$XM/xm.so" 2>/dev/null || cp -f "$KMC/xm.so" "$XM/xm.so" 2>/dev/null || true
cp -f "$XM/xm.so" "$KMC/xm.so" 2>/dev/null || true
chmod 0755 "$XM/xm.so" "$KMC/xm.so" 2>/dev/null || true
"$XM/untether-arm.sh"
FMT="$(cat "$XM/orig_colorinverse.pref" 2>/dev/null || cat "$FMT_FILE" 2>/dev/null || echo Y8)"
/etc/upstart/makexconfig >/dev/null 2>&1 || true
case "$FMT" in
    RGB32*)
        if grep -q 'Depth   8' /var/local/xorg.conf 2>/dev/null; then
            sed -e 's/Depth   8/Depth   24/g' -e 's/Visual  "StaticGray"/Visual  "TrueColor"/g' \
                /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
                mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
        fi
        ;;
esac
if grep -q 'Load "/var/local/xm/xm.so" EndSection Section "Device"' /var/local/xorg.conf 2>/dev/null \
   && grep -Eq "Option      \"FormatEPDC\" \"$FMT\" Option \"Rotate\"" /var/local/xorg.conf 2>/dev/null; then
    hf_log "xorg.conf untether hook verified (FormatEPDC=$FMT)"
else
    hf_log "WARN: xorg.conf verification did not match expected FormatEPDC line — disarming to protect boot"
    "$XM/untether-disarm.sh" >/dev/null 2>&1 || true
fi

echo 0 > "$TRIES_FILE" 2>/dev/null || true
rm -f /dev/.ovl_fw_updated /dev/.ovl_recovery_mode 2>/dev/null || true
/usr/sbin/mntroot ro >/dev/null 2>&1 || /bin/mount -o remount,ro / 2>/dev/null || true

if command -v initctl >/dev/null 2>&1; then
    initctl restart scanner >/dev/null 2>&1 || killall -TERM scanner 2>/dev/null || true
else
    killall -TERM scanner 2>/dev/null || true
fi
if command -v lipc-send-event >/dev/null 2>&1; then
    lipc-send-event com.lab126.scanner doFullScan >/dev/null 2>&1 || true
fi

for gplat in kindlepw2 kindlehf; do
    if [ -f "$KMC/$gplat/bin/gandalf" ]; then
        chown root:root "$KMC/$gplat/bin/gandalf" 2>/dev/null || true
        chmod 6755 "$KMC/$gplat/bin/gandalf" 2>/dev/null || true
        "$CHATTR" +i "$KMC/$gplat/bin/gandalf" 2>/dev/null || true
    fi
done
[ -d /var/local/mkk ] && "$CHATTR" +i /var/local/mkk 2>/dev/null || true

hf_log "v4 ROOTLESS=0 hotfix & untether re-armed."