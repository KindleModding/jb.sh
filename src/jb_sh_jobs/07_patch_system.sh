#!/bin/sh

# Check if we need to do something with the Kindlet developer keystore
# No developer keystore, install it                       		OR  The developer keystore doesn't match - NOTE: This *will* mess with real, official developer keystores. Not that we really care about it, but it should be noted ;).
if [ ! -f "/var/local/java/keystore/developer.keystore" ] || \
	[ "$(md5sum "/var/local/java/keystore/developer.keystore" | cut -d' ' -f1)" != "$(md5sum "/var/local/kmc/system_patches/developer.keystore" | cut -d' ' -f1)" ] ; then
	
	# Install the kindlet keystore
	log "Copying the kindlet keystore"
	# We shouldn't need to do anything specific to read/write /var/local
	if [ "$(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)" -lt "512" ] ; then
		log "Failed to copy the kindlet keystore: not enough space left on device"
		# THIS SHOULD NOT BE POSSIBLE???
	else
		# NOTE: This might have gone poof on newer devices without Kindlet support, so, create it as needed
		mkdir -p "/var/local/java/keystore"
		cp -f "/var/local/kmc/system_patches/developer.keystore" "/var/local/java/keystore/developer.keystore"
	fi
fi

# Run system patch script (what was once the hotfix)

# Detect dm-verity Kindle (or existing /var/local/xm/xm.so install) and pivot to ROOTLESS=0 overlayfs
UNTETHER_ACTIVE=0
if [ $ROOTLESS -eq 1 ] || [ -f /var/local/xm/xm.so ] || [ -b /dev/dm-0 ] || [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" = "overlay" ]; then
	UNTETHER_ACTIVE=1
	log "Detected dm-verity / untether target — installing v4 ROOTLESS=0 untether & pivoting /"

	# 1. Ensure /var/local/kmc and /var/local/mkk are mutable while installing untether
	"${CHATTR}" -i /var/local/kmc 2>/dev/null || true
	find /var/local/kmc -maxdepth 3 \( -type d -o -type f \) -exec "${CHATTR}" -i '{}' \; 2>/dev/null || true
	if [ -d /var/local/mkk ]; then
		"${CHATTR}" -i /var/local/mkk 2>/dev/null || true
		find /var/local/mkk -maxdepth 2 \( -type d -o -type f \) -exec "${CHATTR}" -i '{}' \; 2>/dev/null || true
	fi

	# Preserve clean stock xorg.conf baseline before cold-path cleanup
	rm -f /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	if [ -s /var/local/xorg.conf ] && ! grep -q 'xm\.so' /var/local/xorg.conf 2>/dev/null; then
		cp -f /var/local/xorg.conf /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	elif [ -s /var/local/xm/xorg.conf.stock ] && ! grep -q 'xm\.so' /var/local/xm/xorg.conf.stock 2>/dev/null; then
		cp -f /var/local/xm/xorg.conf.stock /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	elif [ -s /var/local/kmc/xorg.conf.stock ] && ! grep -q 'xm\.so' /var/local/kmc/xorg.conf.stock 2>/dev/null; then
		cp -f /var/local/kmc/xorg.conf.stock /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	elif [ -s /var/local/xorg.conf ]; then
		sed -e 's/\(Option[[:space:]]*"FormatEPDC"[[:space:]]*"[^"]*"\).*/\1/' \
			/var/local/xorg.conf > /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	fi

	# On a fresh cold-path install (when / is still ext2 and not yet overlay),
	# clean any stale unmounted /var/local/.root_ovl or /var/base-local/.root_ovl before preparing fresh overlay
	if grep -q ' / ext2 ' /proc/mounts 2>/dev/null && \
	   [ "$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null)" != "overlay" ]; then
		"${CHATTR}" -R -i /var/local/.root_ovl /var/base-local/.root_ovl /var/local/xm 2>/dev/null || true
		rm -rf /var/local/.root_ovl /var/base-local/.root_ovl /var/local/xm /var/local/xorg.conf.stock /var/local/EPDCMODE_RESET_DONE 2>/dev/null || true
	fi

	mkdir -p /var/local/xm /var/local/kmc /var/local/mkk

	# 2. Save clean stock /var/local/xorg.conf baseline and install /var/local/xm/{xm.so,stage1_pivot.sh,boot.sh,untether-arm.sh,untether-disarm.sh}
	if [ -s /tmp/.xorg.conf.stock.clean ]; then
		cp -f /tmp/.xorg.conf.stock.clean /var/local/xm/xorg.conf.stock 2>/dev/null || true
		cp -f /tmp/.xorg.conf.stock.clean /var/local/kmc/xorg.conf.stock 2>/dev/null || true
		rm -f /tmp/.xorg.conf.stock.clean 2>/dev/null || true
	fi
	for uf in xm.so stage1_pivot.sh boot.sh untether-arm.sh untether-disarm.sh; do
		if [ -f "/var/local/kmc/xm/$uf" ]; then
			cp -f "/var/local/kmc/xm/$uf" "/var/local/xm/$uf"
			cp -f "/var/local/kmc/xm/$uf" "/var/local/kmc/$uf" 2>/dev/null || true
			chmod 755 "/var/local/xm/$uf" "/var/local/kmc/$uf" "/var/local/kmc/xm/$uf" 2>/dev/null || true
		elif [ -f "/var/local/kmc/$uf" ]; then
			cp -f "/var/local/kmc/$uf" "/var/local/xm/$uf"
			chmod 755 "/var/local/xm/$uf" "/var/local/kmc/$uf" 2>/dev/null || true
		fi
	done

	# 3. Reset strike counter, run /var/local/xm/stage1_pivot.sh immediately to pivot /
	#    onto writable overlayfs and strip androidboot.veritymode from /proc/cmdline,
	#    and explicitly guarantee / is remounted rw (even if / was already overlay ro)
	echo 0 > /var/base-local/.ovl_boot_tries 2>/dev/null || true
	/bin/sh /var/local/xm/stage1_pivot.sh
	echo 0 > /var/base-local/.ovl_boot_tries 2>/dev/null || true
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

	# 4. Re-evaluate ROOTLESS=0 after stage1_pivot.sh bind-mounts filtered /proc/cmdline
	ROOTLESS=0
	if cat /proc/cmdline | grep androidboot.veritymode; then
		ROOTLESS=1
	fi
	if [ -f /bin/chattr ]; then
		CHATTR="/bin/chattr"
	elif [ -f /bin/chattr.e2fsprogs ]; then
		CHATTR="/bin/chattr.e2fsprogs"
	fi
	log "Post-pivot ROOTLESS=${ROOTLESS} (root fstype=$(awk '$2 == "/" && $1 != "rootfs" { f=$3 } END { print f }' /proc/mounts 2>/dev/null))"
fi

# Run system patch script (01_mntroot.sh .. 11_reset_patch.sh) in ROOTLESS=0 mode
"${CHATTR}" -i /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
               /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
               /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
               /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
               /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
               /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
if [ $ROOTLESS -eq 0 ]; then
	log "Running system patch script"
	ROOTLESS=$ROOTLESS RUN_MODE=$RUN_MODE JAILBROKEN=$JAILBROKEN sh /var/local/kmc/system_patches/patch_system.sh # Run it directly since jb.sh MUST be run as root
fi

# Finalize v4 untether post-patch setup (libfbink symlinks, untether-rearm.conf, dynconf arm, tries=0)
if [ "$UNTETHER_ACTIVE" -eq 1 ]; then
	/usr/sbin/mntroot rw >/dev/null 2>&1 || /bin/mount -o remount,rw / 2>/dev/null || true
	"${CHATTR}" -i /etc/uks/pubdevkey01.pem /usr/lib/ccat /usr/lib/ccat/sh_integration_extractor.so \
	               /opt/amazon/ebook/lib/json_simple-1.1.jar /usr/bin/logThis.sh \
	               /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC /MNTUS_EXEC \
	               /etc/upstart/kmc.conf /app/kpp_app_cmds.json /usr/share/app/kpp_sys_cmds.json \
	               /usr/bin/otaupd /usr/bin/otaupd.bck /usr/bin/otav3 /usr/bin/otav3.bck \
	               /usr/sbin/factory_reset /usr/sbin/factory_reset.bck 2>/dev/null || true
	[ -f /usr/sbin/factory_reset ] && chmod 0755 /usr/sbin/factory_reset 2>/dev/null || true

	if [ -f /var/local/kmc/lib/libfbink.so ]; then
		ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so.1 2>/dev/null || true
		ln -sf /var/local/kmc/lib/libfbink.so /usr/lib/libfbink.so 2>/dev/null || true
	fi
	for _chroot_ul in /var/tmp/chroot/usr/lib /chroot/usr/lib; do
		if [ -d "$_chroot_ul" ] && awk -v m="$_chroot_ul" '$2 == m && $3 != "overlay" { found=1; exit } END { exit !found }' /proc/mounts 2>/dev/null; then
			umount -l "$_chroot_ul" 2>/dev/null || true
			mount --bind /usr/lib "$_chroot_ul" 2>/dev/null || true
		fi
	done

	# Normalize ownership/permissions through the overlay `/` VFS (never mutate $UPPER directly while mounted)
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
	"${CHATTR}" +i /etc/uks/pubdevkey01.pem /usr/lib/ccat/sh_integration_extractor.so \
	               /usr/bin/logThis.sh /PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC \
	               /MNTUS_EXEC /etc/upstart/kmc.conf 2>/dev/null || true

	"${CHATTR}" -i /etc/upstart/untether-rearm.conf 2>/dev/null || true
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
	chown 0:0 /etc/upstart/untether-rearm.conf 2>/dev/null || true
	chmod 0644 /etc/upstart/untether-rearm.conf 2>/dev/null || true
	if [ -n "$(pidof KPPMainAppV2 KPPMainApp kppmainapp 2>/dev/null)" ]; then
		initctl reload-configuration >/dev/null 2>&1 || true
	fi

	if grep -q " /mnt/us " /proc/mounts 2>/dev/null; then
		/bin/mount -i -o remount,exec /mnt/us 2>/dev/null || \
			/dev/.ovl/old_root/bin/mount -i -o remount,exec /mnt/us 2>/dev/null || \
			/bin/busybox.nosuid mount -o remount,exec /mnt/us 2>/dev/null || true
		[ -L /mnt/us/libkh ] && rm -f /mnt/us/libkh 2>/dev/null || true
		[ -L /mnt/us/libkh/bin ] && rm -f /mnt/us/libkh/bin 2>/dev/null || true
		[ -L /mnt/us/libkh/lib ] && rm -f /mnt/us/libkh/lib 2>/dev/null || true
		mkdir -p /mnt/us/libkh/bin /mnt/us/libkh/lib 2>/dev/null || true
		if [ ! -s /mnt/us/libkh/bin/fbink ]; then
			cp -f /var/local/kmc/bin/fbink /mnt/us/libkh/bin/fbink 2>/dev/null || true
			chmod 755 /mnt/us/libkh/bin/fbink 2>/dev/null || true
		fi
		if [ ! -s /mnt/us/libkh/lib/libfbink.so ]; then
			cp -f /var/local/kmc/lib/libfbink.so /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
			chmod 755 /mnt/us/libkh/lib/libfbink.so 2>/dev/null || true
		fi
	fi

	log "Arming winmgr.colorinverse.pref untether hook"
	cp -f /var/local/kmc/xm/xm.so /var/local/xm/xm.so 2>/dev/null || cp -f /var/local/kmc/xm.so /var/local/xm/xm.so 2>/dev/null || true
	cp -f /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
	chmod 0755 /var/local/xm/xm.so /var/local/kmc/xm.so 2>/dev/null || true
	/var/local/xm/untether-arm.sh
	FMT="$(cat /var/local/xm/orig_colorinverse.pref 2>/dev/null || cat /var/local/xm/.untether-fmt 2>/dev/null || echo Y8)"
	touch /var/local/EPDCMODE_RESET_DONE
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

	# Pre-reboot structural & live Xorg :99 verification of /var/local/xorg.conf and untether scripts
	X99_STATUS="SKIPPED"
	if [ -x /usr/bin/Xorg ]; then
		_x99_dir="/tmp/.xorg99_preflight"
		rm -rf "$_x99_dir" /tmp/nonexistentxm.so /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
		mkdir -p "$_x99_dir"
		sed -e "s|/dev/fb0|$_x99_dir/nonexistent_fb0|g" \
		    -e 's|/var/local/xm/xm\.so|/tmp/nonexistentxm.so|g' \
		    /var/local/xorg.conf > "$_x99_dir/xorg.conf.preboot" 2>/dev/null || true
		/usr/bin/Xorg :99 \
		    -config "$_x99_dir/xorg.conf.preboot" \
		    -logfile "$_x99_dir/Xorg.99.log" \
		    -nolisten tcp >/dev/null 2>&1 || true
		if ! grep -q 'Parse error on line' "$_x99_dir/Xorg.99.log" 2>/dev/null && \
		   grep -q 'nonexistentxm' "$_x99_dir/Xorg.99.log" 2>/dev/null && \
		   grep -q 'LoadModule: "mtk"' "$_x99_dir/Xorg.99.log" 2>/dev/null; then
			X99_STATUS="PASS (parsed cleanly -> LoadModule nonexistentxm -> LoadModule \"mtk\")"
		else
			X99_STATUS="FAIL"
		fi
		rm -rf "$_x99_dir" /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
	fi

	if [ -s /var/local/xm/xm.so ] && [ -s /var/local/xm/xorg.conf.stock ] && \
	   ! grep -q 'xm\.so' /var/local/xm/xorg.conf.stock 2>/dev/null && \
	   /bin/sh -n /var/local/xm/stage1_pivot.sh 2>/dev/null && \
	   /bin/sh -n /var/local/xm/boot.sh 2>/dev/null && \
	   grep -q 'Load "/var/local/xm/xm.so" EndSection Section "Device"' /var/local/xorg.conf 2>/dev/null && \
	   grep -Eq "Option      \"FormatEPDC\" \"$FMT\" Option \"Rotate\"" /var/local/xorg.conf 2>/dev/null && \
	   [ "$X99_STATUS" != "FAIL" ]; then
		log "xorg.conf untether hook verified (FormatEPDC=$FMT, Xorg :99=$X99_STATUS)"
		PREBOOT_VERDICT="PASS"
	else
		log "WARN: pre-reboot validation failed — disarming to protect boot"
		/var/local/xm/untether-disarm.sh >/dev/null 2>&1 || true
		PREBOOT_VERDICT="ABORTED_AND_RESTORED_STOCK"
	fi

	echo 0 > /var/base-local/.ovl_boot_tries 2>/dev/null || true
	echo 0 > /var/base-local/.ovl_boot_count 2>/dev/null || true
	cp -f /etc/version.txt /var/base-local/.root_ovl/fw_version 2>/dev/null || true
	rm -f /dev/.ovl_fw_updated /dev/.ovl_recovery_mode 2>/dev/null || true

	if [ "$PREBOOT_VERDICT" != "PASS" ]; then
		sync
		exit 1
	fi

	if command -v initctl >/dev/null 2>&1; then
		initctl restart scanner >/dev/null 2>&1 || killall -TERM scanner 2>/dev/null || true
	else
		killall -TERM scanner 2>/dev/null || true
	fi
	if command -v lipc-send-event >/dev/null 2>&1; then
		lipc-send-event com.lab126.scanner doFullScan >/dev/null 2>&1 || true
	fi

	# Keep /var/local/kmc mutable for boot.log while locking gandalf and /var/local/mkk with +i
	"${CHATTR}" -i /var/local/kmc 2>/dev/null || true
	for gandalf_platform in kindlepw2 kindlehf; do
		if [ -f "/var/local/kmc/${gandalf_platform}/bin/gandalf" ]; then
			chown root:root "/var/local/kmc/${gandalf_platform}/bin/gandalf" 2>/dev/null || true
			chmod 6755 "/var/local/kmc/${gandalf_platform}/bin/gandalf" 2>/dev/null || true
			"${CHATTR}" +i "/var/local/kmc/${gandalf_platform}/bin/gandalf" 2>/dev/null || true
		fi
	done
	[ -d /var/local/mkk ] && "${CHATTR}" +i /var/local/mkk 2>/dev/null || true
	log "v4 ROOTLESS=0 untether and system patches installed"
	sync
fi