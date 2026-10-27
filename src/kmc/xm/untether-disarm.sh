#!/bin/sh
# remove persistence: restores the saved original (or hardware-matched Y8/RGB32) pref and stock config
CHATTR=/bin/chattr.e2fsprogs; [ -x "$CHATTR" ] || CHATTR=/bin/chattr
rm -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
"$CHATTR" -i /var/local/kmc /var/local/xorg.conf /etc/upstart/untether-rearm.conf 2>/dev/null || true
if [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" != "overlay" ]; then
    "$CHATTR" -i /var/base-local/.root_ovl/upper/etc/upstart/untether-rearm.conf 2>/dev/null || true
    rm -f /var/base-local/.root_ovl/upper/etc/upstart/untether-rearm.conf 2>/dev/null || true
fi
if [ -s /var/local/xm/xorg.conf.stock ]; then
    cp -f /var/local/xm/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
elif [ -s /var/local/kmc/xorg.conf.stock ]; then
    cp -f /var/local/kmc/xorg.conf.stock /var/local/xorg.conf 2>/dev/null || true
fi
find /var/local/kmc -maxdepth 3 \( -type d -o -type f \) -exec "$CHATTR" -i '{}' \; 2>/dev/null || true

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

F=""
for pf in /var/local/xm/orig_colorinverse.pref \
          /var/local/.orig_colorinverse.pref \
          /var/local/kmc/orig_colorinverse.pref \
          /var/local/xm/.untether-fmt \
          /var/local/kmc/.untether-fmt; do
    if [ -f "$pf" ]; then
        CAND="$(cat "$pf" 2>/dev/null || true)"
        case "$CAND" in
            Y8|Y8INV|RGB32|RGB32INV) F="$CAND"; break ;;
        esac
    fi
done
if [ -z "$F" ]; then
    CUR_PREF="$(get-dynconf-value winmgr.colorinverse.pref 2>/dev/null || true)"
    case "$CUR_PREF" in
        Y8|Y8INV|RGB32|RGB32INV) F="$CUR_PREF" ;;
        Y8\"*|Y8INV\"*|RGB32\"*|RGB32INV\"*) F="${CUR_PREF%%\"*}" ;;
    esac
fi
if [ "$IS_COLOR" -eq 1 ]; then
    case "$F" in
        RGB32|RGB32INV) ;;
        Y8INV) F="RGB32INV" ;;
        *) F="RGB32" ;;
    esac
else
    case "$F" in
        Y8|Y8INV) ;;
        RGB32INV) F="Y8INV" ;;
        *) F="Y8" ;;
    esac
fi

set-dynconf-value winmgr.colorinverse.pref "$F"
echo 0 > /var/base-local/.ovl_boot_tries 2>/dev/null || true
for mp in /usr/lib/ccat /etc/uks /etc/upstart /usr/bin/logThis.sh /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json; do
    grep -q " $mp " /proc/mounts 2>/dev/null && umount "$mp" 2>/dev/null || true
done
rm -f /etc/upstart/untether-rearm.conf \
      /var/local/overlay/etc.upstart/untether-rearm.conf \
      /var/local/overlay/etc.upstart/mntus-exec.conf \
      /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
rm -rf /var/local/xm 2>/dev/null || true
/etc/upstart/makexconfig >/dev/null 2>&1 || true
if [ "$IS_COLOR" -eq 1 ] && grep -q 'Depth   8' /var/local/xorg.conf 2>/dev/null; then
    sed -e 's/Depth   8/Depth   24/g' -e 's/Visual  "StaticGray"/Visual  "TrueColor"/g' \
        /var/local/xorg.conf > /var/local/xorg.conf.tmp 2>/dev/null && \
        mv -f /var/local/xorg.conf.tmp /var/local/xorg.conf 2>/dev/null || true
fi
rm -f /var/local/kmc/boot.sh /var/local/kmc/stage1_pivot.sh /var/local/kmc/untether-arm.sh /var/local/kmc/overlay-mount.sh 2>/dev/null || true
G=/var/local/kmc/kindlehf/bin/gandalf
[ -f "$G" ] || G=/var/local/kmc/kindlepw2/bin/gandalf
[ -f "$G" ] && "$CHATTR" +i "$G" 2>/dev/null || true
[ -d /var/local/mkk ] && "$CHATTR" +i /var/local/mkk 2>/dev/null || true
echo "untether removed (kmc files left in place)"
