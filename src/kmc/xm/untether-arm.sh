#!/bin/sh
# Prefer the format cached at install time (orig_colorinverse.pref / .untether-fmt):
# this also runs from the shutdown re-arm job, when the devcap daemon may already be
# stopping (a wrong guess there would default a Colorsoft to Y8 for the next boot).
[ -f /etc/sysconfig/platform_variables ] && . /etc/sysconfig/platform_variables 2>/dev/null
[ -f /etc/sysconfig/board_variables ] && . /etc/sysconfig/board_variables 2>/dev/null
ROT="${DEVICE_ROTATE:-CCW}"
NOACC=true; [ "${ACCELEROMETER:-}" = true ] && NOACC=false

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

CUR_PREF="$(get-dynconf-value winmgr.colorinverse.pref 2>/dev/null || true)"
F=""
case "$CUR_PREF" in
    Y8|Y8INV|RGB32|RGB32INV)
        F="$CUR_PREF"
        ;;
    Y8\"*|Y8INV\"*|RGB32\"*|RGB32INV\"*)
        F="${CUR_PREF%%\"*}"
        ;;
esac

if [ -z "$F" ]; then
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
fi

# Enforce hardware panel family so KSC (calvados) never gets Y8/"" and KS3 never gets RGB32/""
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

mkdir -p /var/local/xm 2>/dev/null || true
if [ ! -f /var/local/xm/xm.so ] && [ ! -e /dev/.ovl_recovery_mode ] && [ -f /var/local/kmc/xm.so ]; then
    cp -f /var/local/kmc/xm.so /var/local/xm/xm.so 2>/dev/null || true
    chmod 755 /var/local/xm/xm.so 2>/dev/null || true
fi
[ -f /var/local/xm/xm.so ] || exit 0

# Save clean stock /var/local/xorg.conf baseline before arming winmgr.colorinverse.pref
if [ -s /var/local/xorg.conf ] && ! grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; then
    cp -f /var/local/xorg.conf /var/local/xm/xorg.conf.stock 2>/dev/null || true
    [ -d /var/local/kmc ] && cp -f /var/local/xorg.conf /var/local/kmc/xorg.conf.stock 2>/dev/null || true
elif [ -s /var/local/xorg.conf ] && { [ ! -s /var/local/xm/xorg.conf.stock ] || grep -q 'xm\.so' /var/local/xm/xorg.conf.stock 2>/dev/null; }; then
    sed -e 's/\(Option[[:space:]]*"FormatEPDC"[[:space:]]*"[^"]*"\).*/\1/' \
        /var/local/xorg.conf > /var/local/xm/xorg.conf.stock 2>/dev/null || true
    [ -d /var/local/kmc ] && cp -f /var/local/xm/xorg.conf.stock /var/local/kmc/xorg.conf.stock 2>/dev/null || true
fi

printf "%s" "$F" > /var/local/xm/orig_colorinverse.pref 2>/dev/null || true
printf "%s" "$F" > /var/local/.orig_colorinverse.pref 2>/dev/null || true
printf "%s" "$F" > /var/local/xm/.untether-fmt 2>/dev/null || true
if [ -d /var/local/kmc ]; then
    printf "%s" "$F" > /var/local/kmc/orig_colorinverse.pref 2>/dev/null || true
    printf "%s" "$F" > /var/local/kmc/.untether-fmt 2>/dev/null || true
fi

set-dynconf-value winmgr.colorinverse.pref "$(printf '%s" Option "Rotate" "%s" Option "NoAccel" "%s" Option "BackingStore" "true" EndSection Section "Module" Load "/var/local/xm/xm.so" EndSection Section "Device" Identifier "dummy" Option "Dummy" "' "$F" "$ROT" "$NOACC")"
touch /var/local/EPDCMODE_RESET_DONE
