#!/bin/sh
# /var/local/xm/boot.sh — Asynchronous Stage-2 ROOTLESS=0 Post-Pivot & Probationary Re-Arm Manager
# Invoked by /var/local/xm/xm.so (v4) via double-fork after stage1_pivot.sh completes.
#
# Probationary Boot Architecture:
#   1. stage1_pivot.sh Line 1 ALREADY unlinked /var/local/xm/xm.so, restored
#      /var/local/xorg.conf from /var/local/xm/xorg.conf.stock, and called sync
#      BEFORE mounting overlayfs or calling pivot_root.
#   2. boot.sh does NOT poke Upstart mid-boot (no `initctl start ...` self-heal),
#      does NOT force-reboot the device (no active watchdog `/sbin/reboot`), and
#      does NOT re-arm xm.so / winmgr.colorinverse.pref / untether-rearm.conf at
#      t ~ 16.5s.
#   3. Instead, boot.sh passively waits (up to 90s) for Xorg + awesome + KPPMainAppV2
#      to be running with unchanged PIDs for 15s (3 x 5s) and `bootactions` stopped,
#      and ONLY THEN copies /var/local/kmc/xm.so -> /var/local/xm/xm.so, runs
#      /var/local/xm/untether-arm.sh, writes /etc/upstart/untether-rearm.conf, calls
#      `initctl reload-configuration`, and resets .ovl_boot_tries = 0.
#   4. If the UI never comes up on boot, boot.sh writes a passive
#      diagnostic log and exits 0 without re-arming xm.so — leaving the device
#      100% disarmed on disk so a single 15s power hold boots 100% stock /dev/dm-0.

for _fd in /proc/$$/fd/*; do
    _fd_num="${_fd##*/}"
    if [ "$_fd_num" -gt 2 ] 2>/dev/null; then
        eval "exec ${_fd_num}>&-" 2>/dev/null || true
    fi
done

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

CHATTR=/bin/chattr.e2fsprogs
[ -x "$CHATTR" ] || CHATTR=/bin/chattr
KMC=/var/local/kmc
XM=/var/local/xm
OVL_BASE=/var/base-local/.root_ovl
TRIES_FILE=/var/base-local/.ovl_boot_tries
BOOT_COUNT_FILE=/var/base-local/.ovl_boot_count

mkdir -p "$XM" "$KMC" 2>/dev/null || true
"$CHATTR" -i "$KMC" "$KMC/boot.log" "$KMC/.untether-fmt" 2>/dev/null || true
LOG="$KMC/boot.log"
touch "$LOG" 2>/dev/null || LOG="$XM/boot.log"
exec </dev/null >>"$LOG" 2>&1
echo "=== boot.sh $(date) [fstype=$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)] ==="

clear_restarts() {
    rm -f /var/run/upstart/*.restarts /var/local/upstart/*.restarts 2>/dev/null || true
}

set_tries() {
    "$CHATTR" -i "$TRIES_FILE" "${TRIES_FILE}.tmp" 2>/dev/null || true
    echo "$1" > "${TRIES_FILE}.tmp" 2>/dev/null && mv -f "${TRIES_FILE}.tmp" "$TRIES_FILE" 2>/dev/null || true
}

resolve_stock_fmt() {
    IS_COLOR=0
    _DC="$(devcap-get-feature -s color.enabled device 2>/dev/null || true)"
    if [ "$_DC" = "true" ]; then
        IS_COLOR=1
    elif [ "$_DC" != "false" ]; then
        if grep -qiE 'calvados|platcs8' /etc/version.txt 2>/dev/null || \
           grep -q 'A3PXY43G91LWNT' /etc/deviceTypes.conf 2>/dev/null || \
           grep -qE 'Depth[[:space:]]+24|Visual[[:space:]]+"TrueColor"|"FormatEPDC"[[:space:]]+"RGB32' /var/local/xorg.conf 2>/dev/null; then
            IS_COLOR=1
        fi
    fi
    DEF_FMT=""
    for pf in /var/local/xm/orig_colorinverse.pref \
              /var/local/.orig_colorinverse.pref \
              /var/local/kmc/orig_colorinverse.pref \
              /var/local/xm/.untether-fmt \
              /var/local/kmc/.untether-fmt; do
        if [ -f "$pf" ]; then
            CAND="$(cat "$pf" 2>/dev/null || true)"
            case "$CAND" in
                Y8|Y8INV|RGB32|RGB32INV) DEF_FMT="$CAND"; break ;;
            esac
        fi
    done
    if [ -z "$DEF_FMT" ]; then
        CUR_PREF="$(get-dynconf-value winmgr.colorinverse.pref 2>/dev/null || true)"
        case "$CUR_PREF" in
            Y8|Y8INV|RGB32|RGB32INV) DEF_FMT="$CUR_PREF" ;;
            Y8\"*|Y8INV\"*|RGB32\"*|RGB32INV\"*) DEF_FMT="${CUR_PREF%%\"*}" ;;
        esac
    fi
    if [ "$IS_COLOR" -eq 1 ]; then
        case "$DEF_FMT" in
            RGB32|RGB32INV) ;;
            Y8INV) DEF_FMT="RGB32INV" ;;
            *) DEF_FMT="RGB32" ;;
        esac
    else
        case "$DEF_FMT" in
            Y8|Y8INV) ;;
            RGB32INV) DEF_FMT="Y8INV" ;;
            *) DEF_FMT="Y8" ;;
        esac
    fi
}

disarm_untether_xorg() {
    echo "FAILSAFE: disarming xorg.conf untether hook"
    rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
    "$CHATTR" -i /var/local/xorg.conf /etc/upstart/untether-rearm.conf 2>/dev/null || true
    if [ -s /var/local/xm/xorg.conf.stock ]; then
        cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    elif [ -s /var/local/kmc/xorg.conf.stock ]; then
        cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    fi
    rm -f /etc/upstart/untether-rearm.conf 2>/dev/null || true
    resolve_stock_fmt
    set-dynconf-value winmgr.colorinverse.pref "$DEF_FMT" 2>/dev/null || true
    rm -f /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
    if [ ! -s /var/local/xorg.conf ] || grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; then
        /etc/upstart/makexconfig >/dev/null 2>&1 || true
    fi
    if [ "$IS_COLOR" -eq 1 ] && grep -q 'Depth   8' /var/local/xorg.conf 2>/dev/null; then
        sed -e 's/Depth   8/Depth   24/g' -e 's/Visual  "StaticGray"/Visual  "TrueColor"/g' \
            /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
            mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
    fi
    sync
}

refresh_chroot_usr_lib() {
    if [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" = "overlay" ]; then
        for _chroot_ul in /var/tmp/chroot/usr/lib /chroot/usr/lib; do
            if [ -d "$_chroot_ul" ] && awk -v m="$_chroot_ul" '$2 == m && $3 != "overlay" { found=1; exit } END { exit !found }' /proc/mounts 2>/dev/null; then
                umount -l "$_chroot_ul" 2>/dev/null || true
                mount --bind /usr/lib "$_chroot_ul" 2>/dev/null || true
            fi
        done
    fi
}

# --- 0A. Immediate Top-of-boot.sh Probationary Disarm (t ~ 15.3s) -------------
rm -f /var/local/xm/xm.so /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
if [ -s /var/local/xm/xorg.conf.stock ] && { [ ! -s /var/local/xorg.conf ] || grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; }; then
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
elif [ -s /var/local/kmc/xorg.conf.stock ] && { [ ! -s /var/local/xorg.conf ] || grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; }; then
    cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
fi
resolve_stock_fmt
for _try in 1 2 3 4 5; do
    set-dynconf-value winmgr.colorinverse.pref "$DEF_FMT" 2>/dev/null || true
    [ "$(get-dynconf-value winmgr.colorinverse.pref 2>/dev/null)" = "$DEF_FMT" ] && break
    sleep 1
done

# --- 0B. Always keep gandalf (setuid-root su) & KMC/MKK links armed first -----
PLATFORM="kindlepw2"
[ -f /lib/ld-linux-armhf.so.3 ] && PLATFORM="kindlehf"
GANDALF="$KMC/$PLATFORM/bin/gandalf"
if [ -f "$GANDALF" ]; then
    if [ ! -u "$GANDALF" ] || [ ! -g "$GANDALF" ] || [ ! -O "$GANDALF" ] || [ ! -G "$GANDALF" ]; then
        "$CHATTR" -i "$GANDALF" 2>/dev/null || true
        chown root:root "$GANDALF" 2>/dev/null || true
        chmod 6755 "$GANDALF" 2>/dev/null || true
    fi
    "$CHATTR" +i "$GANDALF" 2>/dev/null || true
    [ -L "$KMC/$PLATFORM/bin/su" ] || ln -sf "$GANDALF" "$KMC/$PLATFORM/bin/su" 2>/dev/null || true
    [ -L "$KMC/bin" ] || ln -sfn "$KMC/$PLATFORM/bin" "$KMC/bin" 2>/dev/null || true
    [ -L "$KMC/lib" ] || ln -sfn "$KMC/$PLATFORM/lib" "$KMC/lib" 2>/dev/null || true
    if [ ! -L /var/local/mkk/gandalf ] || [ ! -L /var/local/mkk/su ]; then
        "$CHATTR" -i /var/local/mkk 2>/dev/null || true
        mkdir -p /var/local/mkk 2>/dev/null || true
        ln -sf "$KMC/bin/gandalf" /var/local/mkk/gandalf 2>/dev/null || true
        ln -sf /var/local/mkk/gandalf /var/local/mkk/su 2>/dev/null || true
    fi
    "$CHATTR" +i /var/local/mkk 2>/dev/null || true
fi

# --- 1. Handle Tier 1/2 Recovery Modes if /dev/.ovl_recovery_mode or tries >= 3 ---
TRIES="$(cat "$TRIES_FILE" 2>/dev/null)"
case "$TRIES" in
    ''|*[!0-9]*) TRIES=0 ;;
esac

if [ -e /dev/.ovl_needs_reboot ]; then
    echo "FAILSAFE TIER 1: mid-boot overlay quarantine requires immediate reboot into stock /dev/dm-0"
    rm -f /dev/.ovl_needs_reboot 2>/dev/null || true
    sync
    /sbin/reboot -f
    exit 0
fi

if [ -e /dev/.ovl_tier2b_factory_reset ] || [ "$TRIES" -ge 6 ] || \
   [ -e /mnt/base-us/DO_FACTORY_RESTORE ] || [ -e /mnt/us/DO_FACTORY_RESTORE ]; then
    echo "FAILSAFE TIER 2B (tries=$TRIES): invoking /usr/sbin/factory_reset"
    rm -f /dev/.ovl_tier2b_factory_reset 2>/dev/null || true
    set_tries 0
    clear_restarts
    disarm_untether_xorg
    touch /mnt/base-us/DO_FACTORY_RESTORE /mnt/us/DO_FACTORY_RESTORE 2>/dev/null || true
    sync
    /usr/sbin/factory_reset 2>/dev/null || start shutdown SHUTDOWN_MODE=factory_reset 2>/dev/null || true
    exit 0
fi

if [ -e /dev/.ovl_tier2a_restore ] || [ -e /dev/.ovl_untether_disabled ] || [ "$TRIES" -eq 5 ]; then
    echo "FAILSAFE TIER 2A / DISABLE_UNTETHER (tries=$TRIES): disarmed xorg.conf hook"
    rm -f /dev/.ovl_tier2a_restore /dev/.ovl_untether_disabled 2>/dev/null || true
    clear_restarts
    disarm_untether_xorg
    exit 0
fi

if [ -e /dev/.ovl_recovery_mode ] || [ "$TRIES" -ge 3 ]; then
    echo "FAILSAFE TIER 1 (tries=$TRIES): running in stock /dev/dm-0 recovery mode"
fi

ROOT_FSTYPE="$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)"

# --- 2. Overlaid Root Early Setup (NO Early Re-Arm or Upstart Reload!) --------
if [ "$ROOT_FSTYPE" = "overlay" ]; then
    /usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true

    # Ensure /bin/chattr and /sbin/sfdisk symlinks exist
    [ -e /bin/chattr ] || ln -sf /bin/chattr.e2fsprogs /bin/chattr 2>/dev/null || true
    if [ ! -e /sbin/sfdisk ] && [ -x /usr/sbin/sfdisk ]; then
        ln -sf /usr/sbin/sfdisk /sbin/sfdisk 2>/dev/null || true
    fi

    # Ensure /usr/lib/libfbink.so.1 and /usr/lib/libfbink.so symlink to /var/local/kmc/lib/libfbink.so
    if [ -f /var/local/kmc/lib/libfbink.so ]; then
        ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so.1 2>/dev/null || true
        ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so 2>/dev/null || true
    fi

    # Keep /etc/upstart/untether-rearm.conf removed until the 15s UI-stability check passes
    "$CHATTR" -i /etc/upstart/untether-rearm.conf 2>/dev/null || true
    rm -f /etc/upstart/untether-rearm.conf 2>/dev/null || true

    refresh_chroot_usr_lib

    /usr/sbin/mntroot ro >/dev/null 2>&1 || /bin/mount -o remount,ro / 2>/dev/null || true
fi
sync

# --- 3. Detect Firmware Update / Missing kmc.conf (Deferred to Post-GUI Stability) ---
NEED_BG_REPATCH=0
if [ "$ROOT_FSTYPE" = "overlay" ] && [ ! -e /dev/.ovl_recovery_mode ]; then
    if [ -e /dev/.ovl_fw_updated ] || [ ! -f /etc/upstart/kmc.conf ]; then
        NEED_BG_REPATCH=1
    fi
fi

# --- 4. Bind-Mount /bin/true Over wfm_update & Clean Stale OTA Payloads -------
for wfm_bin in /usr/sbin/wfm_update /usr/bin/wfm_update; do
    if [ -e "$wfm_bin" ] && ! grep -q " $wfm_bin " /proc/mounts 2>/dev/null; then
        mount --bind /bin/true "$wfm_bin" 2>/dev/null || true
    fi
done
if [ "$ROOT_FSTYPE" != "overlay" ]; then
    for ota_bin in /usr/bin/otaupd /usr/bin/otav3 /usr/sbin/otaup; do
        if [ -e "$ota_bin" ] && ! grep -q " $ota_bin " /proc/mounts 2>/dev/null; then
            mount --bind /bin/true "$ota_bin" 2>/dev/null || true
        fi
    done
fi

clean_ota_bins() {
    for f in /mnt/us/*.bin /mnt/us/*.bin.tmp /mnt/us/*.tmp.partial \
             /mnt/base-us/*.bin /mnt/base-us/*.bin.tmp /mnt/base-us/*.tmp.partial \
             /mnt/userstore/*.bin /mnt/userstore/*.bin.tmp; do
        [ -e "$f" ] && rm -f "$f" 2>/dev/null || true
    done
}
clean_ota_bins

# --- 5. Ensure /mnt/us Is Remounted exec (-i) & /mnt/us/libkh/{bin,lib} Are Real Dirs ---
setup_mntus_exec() {
    grep -q " /mnt/us " /proc/mounts 2>/dev/null || return 1
    for _df in /mnt/base-us/DISABLE_UNTETHER* /mnt/us/DISABLE_UNTETHER*; do
        if [ -e "$_df" ]; then
            rm -f /mnt/base-us/DISABLE_UNTETHER* /mnt/us/DISABLE_UNTETHER* 2>/dev/null || true
            set_tries 0
            clear_restarts
            touch /dev/.ovl_recovery_mode /dev/.ovl_untether_disabled 2>/dev/null || true
            disarm_untether_xorg
            return 0
        fi
    done
    for _rf in /mnt/base-us/RESET_OVERLAY* /mnt/us/RESET_OVERLAY*; do
        if [ -e "$_rf" ]; then
            rm -f /mnt/base-us/RESET_OVERLAY* /mnt/us/RESET_OVERLAY* 2>/dev/null || true
            touch "$OVL_BASE/.reset_on_next_boot" 2>/dev/null || true
            break
        fi
    done
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
        cp -f "$KMC/$PLATFORM/bin/fbink" /mnt/us/libkh/bin/fbink 2>/dev/null || \
            cp -f /var/local/kmc/bin/fbink /mnt/us/libkh/bin/fbink 2>/dev/null || true
        chmod 755 /mnt/us/libkh/bin/fbink 2>/dev/null || true
    fi
    if [ ! -s /mnt/us/libkh/lib/libfbink.so ]; then
        cp -f "$KMC/$PLATFORM/lib/libfbink.so" /mnt/us/libkh/lib/libfbink.so 2>/dev/null || \
            cp -f /var/local/kmc/lib/libfbink.so /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
        chmod 755 /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
    fi
    if [ -f /mnt/us/emergency.sh ] && [ ! -e /tmp/.kmc_emergency_ran ]; then
        touch /tmp/.kmc_emergency_ran 2>/dev/null || true
        chmod +x /mnt/us/emergency.sh 2>/dev/null || true
        /bin/sh /mnt/us/emergency.sh >>"$LOG" 2>&1 || true
    fi
    return 0
}
if ! setup_mntus_exec; then
    (
        i=0
        while [ "$i" -lt 60 ]; do
            if setup_mntus_exec; then
                clean_ota_bins
                break
            fi
            i=$((i + 1))
            sleep 1
        done
    ) </dev/null >/dev/null 2>&1 &
fi

# --- 6. Optional Root Telnet & User Boot Hooks (FDs Closed to Protect boot.log) ---
if [ -e /mnt/us/ENABLE_TELNET ] || [ -e /mnt/base-us/ENABLE_TELNET ]; then
    iptables -A INPUT -p tcp --dport 23 -j ACCEPT 2>/dev/null || true
    telnetd -l /bin/sh -p 23 </dev/null >/dev/null 2>&1 &
fi

for h in /mnt/us/developer/boot.d/*.sh /var/local/boot.d/*.sh "$KMC"/early.d/*.sh; do
    [ -f "$h" ] && sh "$h" </dev/null >/dev/null 2>&1 &
done

# --- 7. Passive Probationary UI-Stability Check (90s / 3x5s) & Deferred Re-Arm ---
(
    elapsed=0
    stable=0
    while [ "$elapsed" -lt 90 ]; do
        _x_pids="$(pidof Xorg 2>/dev/null)"
        _a_pids="$(pidof awesome 2>/dev/null)"
        _k_pids="$(pidof KPPMainAppV2 2>/dev/null || pidof KPPMainApp 2>/dev/null || pidof kppmainapp 2>/dev/null)"
        XORG_PID="${_x_pids##* }"
        AWE_PID="${_a_pids##* }"
        KPP_PID="${_k_pids##* }"
        if [ -n "$XORG_PID" ] && [ -n "$AWE_PID" ] && [ -n "$KPP_PID" ] && \
           ! initctl status bootactions 2>/dev/null | grep -q "start/running"; then
            stable=1
            checks=0
            while [ "$checks" -lt 3 ]; do
                sleep 5
                elapsed=$((elapsed + 5))
                checks=$((checks + 1))
                _nx="$(pidof Xorg 2>/dev/null)"
                _na="$(pidof awesome 2>/dev/null)"
                _nk="$(pidof KPPMainAppV2 2>/dev/null || pidof KPPMainApp 2>/dev/null || pidof kppmainapp 2>/dev/null)"
                NOW_XORG="${_nx##* }"
                NOW_AWE="${_na##* }"
                NOW_KPP="${_nk##* }"
                if [ "$NOW_XORG" != "$XORG_PID" ] || \
                   [ "$NOW_AWE" != "$AWE_PID" ] || \
                   [ "$NOW_KPP" != "$KPP_PID" ] || \
                   initctl status bootactions 2>/dev/null | grep -q "start/running"; then
                    stable=0
                    break
                fi
            done
            if [ "$stable" -eq 1 ]; then
                if [ "$NEED_BG_REPATCH" -eq 1 ]; then
                    echo "OVL: running deferred patch_system.sh after GUI stability" >>"$LOG"
                    rm -f /dev/.ovl_fw_updated 2>/dev/null || true
                    /usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
                    "$CHATTR" -i /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
                                 /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
                                 /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
                                 /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
                                 /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
                                 /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
                    if [ -f /var/local/kmc/system_patches/patch_system.sh ]; then
                        ROOTLESS=0 RUN_MODE=1 JAILBROKEN=1 /bin/sh /var/local/kmc/system_patches/patch_system.sh >>"$LOG" 2>&1 || true
                    fi
                    if [ -f /var/local/kmc/lib/libfbink.so ]; then
                        ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so.1 2>/dev/null || true
                        ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so 2>/dev/null || true
                    fi
                fi

                if [ ! -e /dev/.ovl_recovery_mode ] && [ "$TRIES" -le 2 ] && [ -s "$KMC/xm.so" ]; then
                    mkdir -p "$XM" 2>/dev/null || true
                    cp -f "$KMC/xm.so" "$XM/xm.so" 2>/dev/null || true
                    chmod 0755 "$XM/xm.so" 2>/dev/null || true
                    if [ -x "$XM/untether-arm.sh" ]; then
                        "$XM/untether-arm.sh" >>"$LOG" 2>&1 || true
                    elif [ -x "$KMC/untether-arm.sh" ]; then
                        "$KMC/untether-arm.sh" >>"$LOG" 2>&1 || true
                    fi
                    touch /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
                    resolve_stock_fmt
                    /etc/upstart/makexconfig >/dev/null 2>&1 || true
                    if [ "$IS_COLOR" -eq 1 ] && grep -q 'Depth   8' /var/local/xorg.conf 2>/dev/null; then
                        sed -e 's/Depth   8/Depth   24/g' -e 's/Visual  "StaticGray"/Visual  "TrueColor"/g' \
                            /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
                            mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
                    fi
                    if [ "$ROOT_FSTYPE" = "overlay" ]; then
                        /usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
                        "$CHATTR" -i /etc/upstart/untether-rearm.conf \
                                     /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
                                     /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
                                     /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
                                     /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
                                     /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
                                     /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
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
                        chown 0:0 / /bin /bin/mount /usr /usr/sbin /usr/sbin/mntroot \
                                  /etc /etc/uks /etc/uks/pubdevkey01.pem /etc/upstart /etc/upstart/kmc.conf /etc/upstart/untether-rearm.conf \
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
                        /usr/sbin/mntroot ro >/dev/null 2>&1 || /bin/mount -o remount,ro / 2>/dev/null || true
                    fi
                fi

                refresh_chroot_usr_lib
                initctl reload-configuration >/dev/null 2>&1 || true
                stop ota-update 2>/dev/null || true
                clean_ota_bins
                setup_mntus_exec || true
                "$CHATTR" -i "$TRIES_FILE" "${TRIES_FILE}.tmp" "$BOOT_COUNT_FILE" "${BOOT_COUNT_FILE}.tmp" 2>/dev/null || true
                echo 0 > "${TRIES_FILE}.tmp" 2>/dev/null && mv -f "${TRIES_FILE}.tmp" "$TRIES_FILE" 2>/dev/null || true
                BOOT_COUNT="$(cat "$BOOT_COUNT_FILE" 2>/dev/null)"
                case "$BOOT_COUNT" in
                    ''|*[!0-9]*) BOOT_COUNT=0 ;;
                esac
                BOOT_COUNT=$((BOOT_COUNT + 1))
                echo "$BOOT_COUNT" > "${BOOT_COUNT_FILE}.tmp" 2>/dev/null && mv -f "${BOOT_COUNT_FILE}.tmp" "$BOOT_COUNT_FILE" 2>/dev/null || true
                rm -f /var/run/upstart/*.restarts /var/local/upstart/*.restarts 2>/dev/null || true
                for stale_dir in "$OVL_BASE"/upper.stale.* "$OVL_BASE"/work.stale.* "$OVL_BASE"/upper.quarantine.* "$OVL_BASE"/work.quarantine.*; do
                    if [ -d "$stale_dir" ]; then
                        find "$stale_dir" -exec "$CHATTR" -i '{}' + 2>/dev/null || true
                        rm -rf "$stale_dir" 2>/dev/null || true
                    fi
                done

                sync
                echo "boot.sh: 15s (3x5s) passive UI-stability check passed (boot #$BOOT_COUNT, Xorg=$XORG_PID, awesome=$AWE_PID, KPPMainAppV2=$KPP_PID); re-armed untether, reloaded Upstart & reset .ovl_boot_tries=0" >>"$LOG"
                exit 0
            fi
        else
            sleep 5
            elapsed=$((elapsed + 5))
        fi
    done

    echo "boot.sh: WARNING — KPPMainAppV2 did not stabilize within 90s; leaving xm.so disarmed on disk (next power cycle boots 100% stock /dev/dm-0)" >>"$LOG"
    rm -f /var/local/xm/xm.so /var/local/EPDCMODE_RESET_DONE /etc/upstart/untether-rearm.conf 2>/dev/null || true
    if [ -s /var/local/xm/xorg.conf.stock ]; then
        cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    fi
    resolve_stock_fmt
    set-dynconf-value winmgr.colorinverse.pref "$DEF_FMT" 2>/dev/null || true
    {
        echo "=== PASSIVE PROBATIONARY BOOT TIMEOUT DIAGNOSTIC ==="
        echo "timestamp: $(date 2>/dev/null)"
        echo "uptime: $(cat /proc/uptime 2>/dev/null)"
        echo "ovl_boot_tries: $(cat "$TRIES_FILE" 2>/dev/null)"
        echo "root_fstype: $(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)"
        echo "xorg_pid: $(pidof Xorg 2>/dev/null || echo none)"
        echo "awesome_pid: $(pidof awesome 2>/dev/null || echo none)"
        echo "kppmainapp_pid: $(pidof KPPMainAppV2 2>/dev/null || pidof KPPMainApp 2>/dev/null || pidof kppmainapp 2>/dev/null || echo none)"
        echo "xm_so_status: $( [ ! -e /var/local/xm/xm.so ] && echo DISARMED_ON_DISK_OK || echo PRESENT )"
        echo "=== initctl list ==="
        initctl list 2>&1 || true
        echo "=== tail -n 80 /var/log/messages ==="
        tail -n 80 /var/log/messages 2>&1 || true
    } > "$KMC/boot-timeout-diag.txt" 2>&1 || true
    sync
    exit 0
) </dev/null >>"$LOG" 2>&1 &

echo "=== boot.sh stage2 dispatched ==="
exit 0
