#!/bin/sh
rm -f /var/local/xm/xm.so 2>/dev/null || true; [ -s /var/local/xm/xorg.conf.stock ] && cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true; sync
# /var/local/xm/stage1_pivot.sh — Synchronous (< 25 ms) ROOTLESS=0 Pivot & Pre-Mount Fail-Safes
# Invoked synchronously by /var/local/xm/xm.so (v4) inside Xorg dlopen() with an 800 ms ceiling.
# Line 1 passively disarms /var/local/xm/xm.so and restores /var/local/xorg.conf.stock before
# mounting overlayfs or calling pivot_root (probationary boot; boot.sh re-arms only after 15s UI stability).

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

CHATTR=/bin/chattr.e2fsprogs
[ -x "$CHATTR" ] || CHATTR=/bin/chattr

OVL_BASE="/var/base-local/.root_ovl"
UPPER="$OVL_BASE/upper"
WORK="$OVL_BASE/work"
TRIES_FILE="/var/base-local/.ovl_boot_tries"
STAGE="/dev/.ovl"
FORCE_RESET_OVL=0

clear_restarts() {
    rm -f /var/run/upstart/*.restarts /var/local/upstart/*.restarts 2>/dev/null || true
}

set_tries() {
    "$CHATTR" -i "$TRIES_FILE" "${TRIES_FILE}.tmp" 2>/dev/null || true
    echo "$1" > "${TRIES_FILE}.tmp" 2>/dev/null && mv -f "${TRIES_FILE}.tmp" "$TRIES_FILE" 2>/dev/null || true
}

fast_disarm_files() {
    rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
    "$CHATTR" -i /var/local/xorg.conf /etc/upstart/untether-rearm.conf 2>/dev/null || true
    if [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" != "overlay" ]; then
        "$CHATTR" -i "$UPPER/etc/upstart/untether-rearm.conf" 2>/dev/null || true
        rm -f "$UPPER/etc/upstart/untether-rearm.conf" 2>/dev/null || true
    fi
    if [ -s /var/local/xm/xorg.conf.stock ]; then
        cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    elif [ -s /var/local/kmc/xorg.conf.stock ]; then
        cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    elif [ -s /var/local/xorg.conf ] && grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; then
        sed -e 's/\(Option[[:space:]]*"FormatEPDC"[[:space:]]*"[^"]*"\).*/\1/' \
            /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
            mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
    fi
    rm -f /var/local/EPDCMODE_RESET_DONE \
          /etc/upstart/untether-rearm.conf 2>/dev/null || true
}

disarm_xorg_hook() {
    fast_disarm_files
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
    set-dynconf-value winmgr.colorinverse.pref "$DEF_FMT" 2>/dev/null || true
    rm -f /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
    /etc/upstart/makexconfig >/dev/null 2>&1 || true
    if [ "$IS_COLOR" -eq 1 ] && grep -q 'Depth   8' /var/local/xorg.conf 2>/dev/null; then
        sed -e 's/Depth   8/Depth   24/g' -e 's/Visual  "StaticGray"/Visual  "TrueColor"/g' \
            /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
            mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
    fi
}

ensure_filtered_cmdline() {
    if grep -q "androidboot.veritymode" /proc/cmdline 2>/dev/null; then
        mkdir -p "$STAGE" 2>/dev/null || true
        chmod 0755 "$STAGE" 2>/dev/null || true
        sed -e 's/androidboot\.veritymode=[^ ]*//g' \
            -e 's/androidboot\.unlocked_kernel=false/androidboot.unlocked_kernel=true/g' \
            /proc/cmdline > "$STAGE/cmdline.rootless0" 2>/dev/null
        if [ -s "$STAGE/cmdline.rootless0" ]; then
            if [ -x "$STAGE/old_root/bin/mount" ]; then
                "$STAGE/old_root/bin/mount" -n --bind "$STAGE/cmdline.rootless0" /proc/cmdline 2>/dev/null || \
                "$STAGE/old_root/bin/mount" --bind "$STAGE/cmdline.rootless0" /proc/cmdline 2>/dev/null || true
            else
                /bin/mount -n --bind "$STAGE/cmdline.rootless0" /proc/cmdline 2>/dev/null || \
                /bin/mount --bind "$STAGE/cmdline.rootless0" /proc/cmdline 2>/dev/null || true
            fi
        fi
    fi
}

install_mount_and_mntroot_wrappers() {
    _target_root="${1-$UPPER}"
    mkdir -p "$_target_root/bin" "$_target_root/sbin" "$_target_root/usr/sbin" "$_target_root/etc/upstart" "$_target_root/usr/lib" 2>/dev/null || true
    "$CHATTR" -i "$_target_root/bin" "$_target_root/bin/mount" "$_target_root/bin/chattr" \
                 "$_target_root/sbin" "$_target_root/sbin/sfdisk" \
                 "$_target_root/usr/sbin" "$_target_root/usr/sbin/mntroot" 2>/dev/null || true
    rm -f "$_target_root/bin/mount" "$_target_root/usr/sbin/mntroot" 2>/dev/null || true

    # 5a. Ensure bin/chattr -> /bin/chattr.e2fsprogs and sbin/sfdisk -> /usr/sbin/sfdisk symlinks exist
    [ -L "$_target_root/bin/chattr" ] || ln -sf /bin/chattr.e2fsprogs "$_target_root/bin/chattr" 2>/dev/null || true
    if [ ! -e "/sbin/sfdisk" ] && [ -x "/usr/sbin/sfdisk" ]; then
        [ -L "$_target_root/sbin/sfdisk" ] || ln -sf /usr/sbin/sfdisk "$_target_root/sbin/sfdisk" 2>/dev/null || true
    fi

    # 5b. Install bin/mount wrapper
    cat > "$_target_root/bin/mount" <<'MOUNT_WRAP_EOF'
#!/bin/sh
REAL_MOUNT="/dev/.ovl/old_root/bin/mount"
[ -x "$REAL_MOUNT" ] || REAL_MOUNT="/dev/.ovl/lower/bin/mount"

is_root_target=0
is_mntus_target=0
is_bind_mount=0
remount_mode=""
has_exec_only=0
has_remount_exec=0
prev=""
for arg in "$@"; do
    [ "$arg" = "/" ] && is_root_target=1
    case "$arg" in
        /mnt/us|/mnt/us/) is_mntus_target=1 ;;
        --bind|--rbind|-B|-R) is_bind_mount=1 ;;
    esac
    if [ "$prev" = "-o" ]; then
        case ",$arg," in
            *,bind,*|*,rbind,*) is_bind_mount=1 ;;
        esac
        case ",$arg," in
            *,remount,*ro,*|*,ro,*remount,*) remount_mode="ro" ;;
            *,remount,*rw,*|*,rw,*remount,*) remount_mode="rw" ;;
            *,remount,*exec,*|*,exec,*remount,*) has_remount_exec=1 ;;
            ,exec,) has_exec_only=1 ;;
        esac
    fi
    case "$arg" in
        -o*)
            opts="${arg#-o}"
            case ",$opts," in
                *,bind,*|*,rbind,*) is_bind_mount=1 ;;
            esac
            case ",$opts," in
                *,remount,*ro,*|*,ro,*remount,*) remount_mode="ro" ;;
                *,remount,*rw,*|*,rw,*remount,*) remount_mode="rw" ;;
                *,remount,*exec,*|*,exec,*remount,*) has_remount_exec=1 ;;
                ,exec,) has_exec_only=1 ;;
            esac
            ;;
    esac
    prev="$arg"
done

if [ "$is_bind_mount" -eq 0 ] && [ "$is_root_target" -eq 1 ] && [ "$remount_mode" = "rw" ]; then
    "$REAL_MOUNT" -n -o remount,bind,rw /dev/root / 2>/dev/null || true
    "$REAL_MOUNT" -n -t overlay -o remount,rw /dev/root / 2>/dev/null || true
    exit 0
elif [ "$is_bind_mount" -eq 0 ] && [ "$is_root_target" -eq 1 ] && [ "$remount_mode" = "ro" ]; then
    sync
    exit 0
elif [ "$is_bind_mount" -eq 0 ] && [ "$is_mntus_target" -eq 1 ] && { [ "$has_exec_only" -eq 1 ] || [ "$has_remount_exec" -eq 1 ]; } && grep -q " /mnt/us " /proc/mounts 2>/dev/null; then
    "$REAL_MOUNT" -i -o remount,exec /mnt/us 2>/dev/null || /bin/busybox.nosuid mount -o remount,exec /mnt/us 2>/dev/null || true
    exit 0
fi

if [ -x "$REAL_MOUNT" ]; then
    exec "$REAL_MOUNT" "$@"
fi
exec /bin/busybox.nosuid mount "$@"
MOUNT_WRAP_EOF
    chmod 0755 "$_target_root/bin/mount" 2>/dev/null || true

    # 5c. Install patched usr/sbin/mntroot (awk '$2 == "/" { print $4 }' and fixed [ "$unlockedKernel" spacing)
    cat > "$_target_root/usr/sbin/mntroot" <<'MNTROOT_EOF'
#!/bin/sh
[ -f /usr/bin/record_device_metric.sh ] && . /usr/bin/record_device_metric.sh
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}
type msg >/dev/null 2>&1 || msg() { :; }
type record_minerva_metric >/dev/null 2>&1 || record_minerva_metric() { :; }

CURRENT_STATE_RO=0

MOUNT_BIN="/bin/mount"
MOUNT_ARGS_RO="-o remount,ro"
MOUNT_ARGS_RW="-o remount,rw"

MSG_RO="read-only"
MSG_RW="writeable"
MSG_MAKING="Making root filesystem "
MSG_REMOUNT="Done re-mounting root filesystem as "
MSG_FAILREMOUNT="Re-mounting root filesystem failed"
MSG_NTBD="Nothing to be done"

prodVersion=0
unlockedKernel=true
secureCpu=0
veritymode=disabled

for i in $(cat /proc/cmdline); do
  case "$i" in
    androidboot.prod*)
      val=$i
      prodVersion=${val##*=}
      ;;
    androidboot.unlocked_kernel*)
      val=$i
      unlockedKernel=${val##*=}
      ;;
    secure_cpu*)
      val=$i
      secureCpu=${val##*=}
      ;;
    androidboot.veritymode*)
      val=$i
      veritymode=${val##*=}
      ;;
  esac
done

current_state()
{
    { [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$4 } END { print f }' /proc/mounts | awk -F',' '{print $1}')" = "rw" ] && CURRENT_STATE_RO=0; } || CURRENT_STATE_RO=1
    { [ $CURRENT_STATE_RO -eq 1 ] && msg "Currently $MSG_RO" D; } || msg "Currently $MSG_RW" D
}

mount_ro()
{
    msg "$MSG_MAKING$MSG_RO" I
    current_state
    if [ $CURRENT_STATE_RO -eq 0 ]; then
        $MOUNT_BIN $MOUNT_ARGS_RO /
        if [ $? -eq 0 ]; then
            msg "$MSG_REMOUNT$MSG_RO" D
        else
            msg "$MSG_FAILREMOUNT" E
        fi
    else
        msg "$MSG_NTBD" D
    fi
}

mntroot_metric()
{
    name=$1
    process_name=$2
    mode=$3
    if [ "$mode" = "0" ]; then
        schema="ct44/2/02330470"
    else
        schema="n1la/2/01330470"
    fi
    version=$(cat /etc/prettyversion.txt | cut -d' ' -f2)
    record_minerva_metric "ax0m4rye" "$schema" $LABEL_MINERVA_TYPE_STRING "Name" $name \
                                               $LABEL_MINERVA_TYPE_STRING "Program" $process_name \
                                               $LABEL_MINERVA_TYPE_STRING "OSVersion" "$version" \
                                               $LABEL_MINERVA_TYPE_LONG "Count" 1 \
                                               $LABEL_MINERVA_TYPE_PREDEFINED $LABEL_MINERVA_PREDEFINED_DEVICE_ID \
                                               $LABEL_MINERVA_TYPE_PREDEFINED $LABEL_MINERVA_PREDEFINED_DEVICE_TYPE \
                                               $LABEL_MINERVA_TYPE_PREDEFINED $LABEL_MINERVA_PREDEFINED_MARKETPLACE_ID
}

mount_rw()
{
    pid=$(awk '/PPid/ {print $2}' /proc/$$/status 2>/dev/null)
    if [ -z "$pid" ] || [ "$pid" -eq 0 ]; then
        pid="N/A"
        process_name="N/A"
    else
        process_name=$(cat /proc/$pid/comm 2>/dev/null)
    fi
    if [ "$prodVersion" = "1" ] && [ "$unlockedKernel" = "false" ] && [ "$secureCpu" = "1" ]; then
        msg "MNTROOT_VERITY_ON_LOCKED Called by $process_name, with a PID of ($pid)" W
        mntroot_metric "MNTROOT_VERITY_ON_LOCKED" "$process_name" "0"
        exit 0
    else
        if [ "$veritymode" = "enforcing" ]; then
            mntroot_metric "MNTROOT_VERITY_ON_UNLOCKED" "$process_name" "1"
            msg "MNTROOT_VERITY_ON_UNLOCKED Called by $process_name, with a PID of ($pid)" W
            exit 0
        else
            msg "MNTROOT_VERITY_OFF_UNLOCKED Called by $process_name, with a PID of ($pid)" W
        fi
    fi
    msg "$MSG_MAKING$MSG_RW" I
    current_state
    if [ $CURRENT_STATE_RO -eq 1 ]; then
        $MOUNT_BIN $MOUNT_ARGS_RW /
        if [ $? -eq 0 ]; then
            msg "$MSG_REMOUNT$MSG_RW" D
        else
            msg "$MSG_FAILREMOUNT" E
        fi
    else
        msg "$MSG_NTBD" D
    fi
}

case "$1" in
    ro)
        mount_ro
        ;;
    rw)
        mount_rw
        ;;
    help|-h|--help)
        msg "Usage: $0 (ro|rw)" I
        ;;
    *)
        current_state
        { [ $CURRENT_STATE_RO -eq 1 ] && exit 5 ; } || exit 6
        ;;
esac

exit 0
MNTROOT_EOF
    chmod 0755 "$_target_root/usr/sbin/mntroot" 2>/dev/null || true
}

# --- 1. Pre-Mount Strike Counter (/var/base-local/.ovl_boot_tries) & Recovery Sentinels ---
# Read and increment /var/base-local/.ovl_boot_tries on EVERY invocation BEFORE
# checking if / is already overlayfs (protects against post-pivot Xorg restart loops).
TRIES="$(cat "$TRIES_FILE" 2>/dev/null)"
case "$TRIES" in
    ''|*[!0-9]*) TRIES=0 ;;
esac
TRIES=$((TRIES + 1))
set_tries "$TRIES"

# Check userstore recovery flags (/mnt/base-us/DISABLE_UNTETHER*, /mnt/us/DISABLE_UNTETHER*,
# /mnt/base-us/RESET_OVERLAY*, /mnt/us/RESET_OVERLAY*)
for f in /mnt/base-us/DISABLE_UNTETHER* /mnt/us/DISABLE_UNTETHER* /mnt/userstore/edata/DISABLE_UNTETHER*; do
    if [ -e "$f" ]; then
        rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
        cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
        rm -f /mnt/base-us/DISABLE_UNTETHER* /mnt/us/DISABLE_UNTETHER* /mnt/userstore/edata/DISABLE_UNTETHER* 2>/dev/null || true
        set_tries 0
        clear_restarts
        touch /dev/.ovl_recovery_mode /dev/.ovl_untether_disabled 2>/dev/null || true
        disarm_xorg_hook
        exit 0
    fi
done

for f in /mnt/base-us/RESET_OVERLAY* /mnt/us/RESET_OVERLAY* /mnt/userstore/edata/RESET_OVERLAY* "$OVL_BASE/.reset_on_next_boot"; do
    if [ -e "$f" ]; then
        rm -f /mnt/base-us/RESET_OVERLAY* /mnt/us/RESET_OVERLAY* /mnt/userstore/edata/RESET_OVERLAY* "$OVL_BASE/.reset_on_next_boot" 2>/dev/null || true
        TRIES=1
        set_tries 1
        clear_restarts
        FORCE_RESET_OVL=1
        break
    fi
done

ROOT_FSTYPE="$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)"

# Tier 2B (tries >= 6): < 2 ms fast disarm of xm.so + xorg.conf FIRST,
# touch /mnt/base-us/DO_FACTORY_RESTORE and /mnt/us/DO_FACTORY_RESTORE, then disarm dynconf and exit 0.
if [ "$TRIES" -ge 6 ]; then
    rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    clear_restarts
    touch /mnt/base-us/DO_FACTORY_RESTORE /mnt/us/DO_FACTORY_RESTORE \
          /dev/.ovl_recovery_mode /dev/.ovl_tier2b_factory_reset 2>/dev/null || true
    disarm_xorg_hook
    exit 0
fi

# Tier 2A (tries == 5): < 2 ms fast disarm of xm.so + xorg.conf FIRST,
# clear .restarts, touch /var/base-local/RESTORE_VAR_LOCAL, then disarm dynconf and exit 0.
if [ "$TRIES" -eq 5 ]; then
    rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
    clear_restarts
    touch /var/base-local/RESTORE_VAR_LOCAL \
          /dev/.ovl_recovery_mode /dev/.ovl_tier2a_restore 2>/dev/null || true
    disarm_xorg_hook
    exit 0
fi

# Tier 1 (tries == 3 or tries == 4): Quarantine /var/base-local/.root_ovl/upper -> upper.quarantine.$$,
# clear /var/run/upstart/*.restarts and /var/local/upstart/*.restarts, create /dev/.ovl_recovery_mode,
# and exit 0 without mounting overlayfs (booting 100% stock /dev/dm-0).
if [ "$TRIES" -eq 3 ] || [ "$TRIES" -eq 4 ]; then
    clear_restarts
    "$CHATTR" -i "$OVL_BASE" "$UPPER" "$WORK" 2>/dev/null || true
    [ -d "$UPPER" ] && mv -f "$UPPER" "$OVL_BASE/upper.quarantine.$$" 2>/dev/null || true
    [ -d "$WORK" ]  && mv -f "$WORK"  "$OVL_BASE/work.quarantine.$$"  2>/dev/null || true
    touch /dev/.ovl_recovery_mode 2>/dev/null || true
    if [ "$ROOT_FSTYPE" = "overlay" ]; then
        touch /dev/.ovl_needs_reboot 2>/dev/null || true
    fi
    exit 0
fi

# --- 2. Idempotency Check (Ensure / is remounted rw when already on overlay) ---
if [ "$ROOT_FSTYPE" = "overlay" ]; then
    chmod 0755 /dev/.ovl "$STAGE" 2>/dev/null || true
    for _rmnt in /dev/.ovl/old_root/bin/mount /dev/.ovl/lower/bin/mount /bin/mount; do
        if [ -x "$_rmnt" ]; then
            "$_rmnt" -n -o remount,bind,rw /dev/root / 2>/dev/null || true
            "$_rmnt" -n -t overlay -o remount,rw /dev/root / 2>/dev/null || true
            "$_rmnt" -n -o remount,rw / 2>/dev/null || true
            break
        fi
    done
    install_mount_and_mntroot_wrappers ""
    /usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
    [ -e /bin/chattr ] || ln -sf /bin/chattr.e2fsprogs /bin/chattr 2>/dev/null || true
    if [ ! -e /sbin/sfdisk ] && [ -x /usr/sbin/sfdisk ]; then
        ln -sf /usr/sbin/sfdisk /sbin/sfdisk 2>/dev/null || true
    fi
    [ -f "$OVL_BASE/fw_version" ] || cp -f /etc/version.txt "$OVL_BASE/fw_version" 2>/dev/null || true
    ensure_filtered_cmdline
    exit 0
fi

# Verify /var/base-local is mounted
grep -q " /var/base-local " /proc/mounts 2>/dev/null || exit 0
"$CHATTR" -i "$OVL_BASE" 2>/dev/null || true
mkdir -p "$OVL_BASE" 2>/dev/null || exit 0

# --- 3. Firmware Version Stamp Guard (/var/base-local/.root_ovl/fw_version vs. /etc/version.txt) ---
if [ "$FORCE_RESET_OVL" -eq 1 ] || \
   { [ -f "$OVL_BASE/fw_version" ] && ! cmp -s /etc/version.txt "$OVL_BASE/fw_version" 2>/dev/null; }; then
    "$CHATTR" -i "$UPPER" "$WORK" 2>/dev/null || true
    [ -d "$UPPER" ] && mv -f "$UPPER" "$OVL_BASE/upper.stale.$$" 2>/dev/null || true
    [ -d "$WORK" ]  && mv -f "$WORK"  "$OVL_BASE/work.stale.$$"  2>/dev/null || true
    mkdir -p "$UPPER" "$WORK" 2>/dev/null || true
    cp -f /etc/version.txt "$OVL_BASE/fw_version" 2>/dev/null || true
    touch /dev/.ovl_fw_updated 2>/dev/null || true
elif [ ! -f "$OVL_BASE/fw_version" ]; then
    mkdir -p "$UPPER" "$WORK" 2>/dev/null || true
    cp -f /etc/version.txt "$OVL_BASE/fw_version" 2>/dev/null || true
    touch /dev/.ovl_fw_updated 2>/dev/null || true
fi

# --- 4. Pre-Mount Hygiene & Fast-Path Check (< 40 ms inside Xorg's 800 ms window) ---
# 4a. Recreate /var/base-local/.root_ovl/work (rm -rf + mkdir -p)
"$CHATTR" -i "$WORK" "$WORK/work" 2>/dev/null || true
rm -rf "$WORK" 2>/dev/null || true
mkdir -p "$UPPER" "$WORK" 2>/dev/null || exit 0

if [ "$FORCE_RESET_OVL" -eq 0 ] && [ ! -e /dev/.ovl_fw_updated ] && \
   [ -x "$UPPER/bin/mount" ] && [ -x "$UPPER/usr/sbin/mntroot" ] && [ -L "$UPPER/bin/chattr" ]; then
    # Fast-path (< 40 ms): $UPPER/bin/mount and $UPPER/usr/sbin/mntroot were already
    # prepared and normalized pre-reboot; skip slow recursive find/chown/chmod/sh -n on $UPPER.
    if [ ! -e "/sbin/sfdisk" ] && [ -x "/usr/sbin/sfdisk" ] && [ ! -L "$UPPER/sbin/sfdisk" ]; then
        mkdir -p "$UPPER/sbin" 2>/dev/null || true
        ln -sf /usr/sbin/sfdisk "$UPPER/sbin/sfdisk" 2>/dev/null || true
    fi
else
    # Cold-path: prune any legacy stock /usr/lib/ccat copy-ups BEFORE overlayfs is mounted,
    # normalize ownership/permissions, scrub 0-byte files/whiteouts, validate upper scripts,
    # and seed /bin/mount & /usr/sbin/mntroot wrappers.
    if [ -d "$UPPER/usr/lib/ccat" ]; then
        for _cf in "$UPPER/usr/lib/ccat/"*; do
            [ -e "$_cf" ] || continue
            _cbase="${_cf##*/}"
            [ "$_cbase" = "sh_integration_extractor.so" ] && continue
            if [ -e "/usr/lib/ccat/$_cbase" ]; then
                "$CHATTR" -i "$_cf" 2>/dev/null || true
                rm -f "$_cf" 2>/dev/null || true
            fi
        done
    fi
    find "$OVL_BASE" \( -type d -o -type f \) -exec "$CHATTR" -i '{}' + 2>/dev/null || true
    chown -R 0:0 "$OVL_BASE" 2>/dev/null || true
    chmod -R g-s,go-w "$UPPER" 2>/dev/null || true
    find "$UPPER" -type d -exec chmod 0755 '{}' + 2>/dev/null || true

    # 4c. Scrub any 0-byte regular file in upper (except /MNTUS_EXEC and
    #     /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC) that shadows a non-empty file on /
    find "$UPPER" -type f -size 0 2>/dev/null | while IFS= read -r f; do
        rel="${f#$UPPER/}"
        case "/$rel" in
            /MNTUS_EXEC|/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC) continue ;;
        esac
        if [ -s "/$rel" ]; then
            "$CHATTR" -i "${f%/*}" "$f" 2>/dev/null || true
            rm -f "$f" 2>/dev/null || true
        fi
    done

    # 4d. Remove any accidental character-device whiteout ([ -c "$f" ]) at critical boot paths
    for f in "$UPPER/sbin/init"* \
             "$UPPER/usr/bin/Xorg" \
             "$UPPER/usr/bin/lxinit" \
             "$UPPER/usr/bin/awesome" \
             "$UPPER/app/bin/KPPMainApp"* \
             "$UPPER/bin/sh" \
             "$UPPER/bin/mount"*; do
        if [ -c "$f" ]; then
            "$CHATTR" -i "${f%/*}" "$f" 2>/dev/null || true
            rm -f "$f" 2>/dev/null || true
        fi
    done

    # 4e. Validate upper shell scripts & Upstart jobs in upper/etc/upstart/*, upper/usr/sbin/mntroot, upper/bin/mount
    for f in "$UPPER/etc/upstart/"* "$UPPER/usr/sbin/mntroot" "$UPPER/bin/mount"; do
        if [ -f "$f" ]; then
            case "$f" in
                *.conf)
                    if ! awk '
                        /^[[:space:]]*((pre-start|post-start|pre-stop|post-stop)[[:space:]]+)?script([[:space:]]|$)/ { in_s++; next }
                        /^[[:space:]]*end[[:space:]]+script([[:space:]]|$)/ { in_s--; next }
                        END { if (in_s != 0) exit 1 }
                    ' "$f" 2>/dev/null || ! awk '
                        /^[[:space:]]*((pre-start|post-start|pre-stop|post-stop)[[:space:]]+)?script([[:space:]]|$)/ { next }
                        /^[[:space:]]*end[[:space:]]+script([[:space:]]|$)/ { next }
                        /^[[:space:]]*(start|stop)[[:space:]]+on([[:space:]]|$)/ { next }
                        { print }
                    ' "$f" 2>/dev/null | /bin/sh -n 2>/dev/null; then
                        "$CHATTR" -i "${f%/*}" "$f" 2>/dev/null || true
                        rm -f "$f" 2>/dev/null || true
                    fi
                    ;;
                *)
                    if ! /bin/sh -n "$f" 2>/dev/null; then
                        "$CHATTR" -i "${f%/*}" "$f" 2>/dev/null || true
                        rm -f "$f" 2>/dev/null || true
                    fi
                    ;;
            esac
        fi
    done

    # --- 5. Seed /bin/mount Wrapper & Patched /usr/sbin/mntroot in upperdir ---
    install_mount_and_mntroot_wrappers "$UPPER"
    chown -R 0:0 "$OVL_BASE" 2>/dev/null || true
fi

# --- 6. Loop-Free overlayfs Mount + MS_MOVE of All Submounts + pivot_root ---
mkdir -p "$STAGE/lower" "$STAGE/old_root" 2>/dev/null || exit 0
chmod 0755 "$STAGE" 2>/dev/null || true

# Note: If /mnt/rwfs exists as an unmounted directory on /, linking /dev/.ovl/new_root -> /mnt/rwfs
# attaches M_ovl directly to M1 (/) rather than inside M_dev, avoiding -ELOOP when moving /dev.
if [ -d /mnt/rwfs ] && ! grep -q " /mnt/rwfs " /proc/mounts 2>/dev/null; then
    rm -rf "$STAGE/new_root" 2>/dev/null || true
    ln -sfn /mnt/rwfs "$STAGE/new_root" 2>/dev/null || mkdir -p "$STAGE/new_root"
else
    mkdir -p "$STAGE/new_root" 2>/dev/null || exit 0
fi

mount -n --make-rprivate / 2>/dev/null || mount --make-rprivate / 2>/dev/null || true
if ! grep -q " $STAGE/lower " /proc/mounts 2>/dev/null; then
    mount -n --bind / "$STAGE/lower" 2>/dev/null || mount --bind / "$STAGE/lower" || exit 0
fi

if ! mount -n -t overlay /dev/root \
    -o "rw,noatime,lowerdir=/dev/.ovl/lower,upperdir=/var/base-local/.root_ovl/upper,workdir=/var/base-local/.root_ovl/work" \
    /dev/.ovl/new_root 2>/dev/null && \
   ! mount -t overlay /dev/root \
    -o "rw,noatime,lowerdir=/dev/.ovl/lower,upperdir=/var/base-local/.root_ovl/upper,workdir=/var/base-local/.root_ovl/work" \
    /dev/.ovl/new_root 2>/dev/null; then
    umount -l "$STAGE/lower" 2>/dev/null || true
    "$CHATTR" -i "$UPPER" 2>/dev/null || true
    mv -f "$UPPER" "$OVL_BASE/upper.quarantine.$$" 2>/dev/null || true
    touch /dev/.ovl_recovery_mode 2>/dev/null || true
    exit 0
fi

# 6a. Move explicit direct child mounts of / (moving /proc right before /dev so /proc/mounts
#     remains readable at /proc/mounts throughout the submount loop, and moving /dev last)
for mp in /sys /var /pdata /keys \
          /mnt/wfm /mnt/kfxcache /mnt/userstore /mnt/base-us /mnt/us \
          /usr/share/X11/xkb /usr/java/lib/fonts /etc/kdb.src \
          /usr/lib/locale /usr/share/keyboard /usr/lib/tts /usr/bin/chromium; do
    if awk -v m="$mp" '$2 == m { found=1; exit } END { exit !found }' /proc/mounts; then
        mkdir -p "/dev/.ovl/new_root${mp}" 2>/dev/null || true
        mount -n --move "$mp" "/dev/.ovl/new_root${mp}" 2>/dev/null || \
            mount --move "$mp" "/dev/.ovl/new_root${mp}" 2>/dev/null || true
    fi
done

# 6b. Move any other direct child mounts of / (e.g. from /etc/loopbacktab or /mnt/*)
if [ -f /etc/loopbacktab ]; then
    grep -v '^#' /etc/loopbacktab 2>/dev/null | while IFS= read -r lb_mp; do
        [ -n "$lb_mp" ] || continue
        if awk -v m="$lb_mp" '$2 == m { found=1; exit } END { exit !found }' /proc/mounts 2>/dev/null; then
            mkdir -p "/dev/.ovl/new_root${lb_mp}" 2>/dev/null || true
            mount -n --move "$lb_mp" "/dev/.ovl/new_root${lb_mp}" 2>/dev/null || \
                mount --move "$lb_mp" "/dev/.ovl/new_root${lb_mp}" 2>/dev/null || true
        fi
    done
fi

awk '
    $2 != "/" && $2 != "/mnt/rwfs" && $2 != "/dev/.ovl/new_root" &&
    $2 != "/proc" && $2 != "/dev" &&
    $2 !~ /^\/dev\// && $2 !~ /^\/proc\// && $2 !~ /^\/sys\// && $2 !~ /^\/var\// &&
    $2 !~ /^\/mnt\/rwfs\// { print $2 }
' /proc/mounts 2>/dev/null | while IFS= read -r extra_mp; do
    [ -n "$extra_mp" ] || continue
    mkdir -p "/dev/.ovl/new_root${extra_mp}" 2>/dev/null || true
    mount -n --move "$extra_mp" "/dev/.ovl/new_root${extra_mp}" 2>/dev/null || \
        mount --move "$extra_mp" "/dev/.ovl/new_root${extra_mp}" 2>/dev/null || true
done

# Move /proc onto /dev/.ovl/new_root/proc
if awk '$2 == "/proc" { found=1; exit } END { exit !found }' /proc/mounts; then
    mkdir -p /dev/.ovl/new_root/proc 2>/dev/null || true
    mount -n --move /proc /dev/.ovl/new_root/proc 2>/dev/null || \
        mount --move /proc /dev/.ovl/new_root/proc 2>/dev/null || true
fi

# 6c. Prepare old_root, enter /dev/.ovl/new_root, move /dev last, and pivot_root
#     (Do NOT umount -l old_root so M1 stays attached in init_mnt_ns.)
mkdir -p /dev/.ovl/new_root/dev /dev/.ovl/old_root 2>/dev/null || true
cd /dev/.ovl/new_root || exit 0
mount -n --move /dev dev 2>/dev/null || mount --move /dev dev 2>/dev/null || true
mkdir -p dev/.ovl/old_root 2>dev/null || true
/sbin/pivot_root . dev/.ovl/old_root || dev/.ovl/lower/sbin/pivot_root . dev/.ovl/old_root || exit 0
cd /

# --- 7. Filtered /proc/cmdline Bind-Mount ---
ensure_filtered_cmdline

exit 0
