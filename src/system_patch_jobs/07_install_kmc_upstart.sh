#!/bin/sh

if [ $ROOTLESS -eq 0 ]; then
	# Check if we need to do something with the KMC jobs
	if [ -f "/var/local/kmc/system_patches/emergency.conf" ] ; then
		if [ -f "/etc/upstart/kmc.conf" ]; then
			make_mutable "/etc/upstart/kmc.conf" 
			rm -rf "/etc/upstart/kmc.conf" # Kill the old kmc.conf
		fi
		if [ ! -f "/etc/upstart/emergency.conf" ] ; then
			make_mutable "/etc/upstart/emergency.conf"
			rm -rf "/etc/upstart/emergency.conf"
			cp -f "/var/local/kmc/system_patches/emergency.conf" "/etc/upstart/emergency.conf"
			chmod 0664 "/etc/upstart/emergency.conf"
			make_immutable "/etc/upstart/emergency.conf"
		fi
		if [ ! -f "/etc/upstart/run_patch.conf" ] ; then
			make_mutable "/etc/upstart/run_patch.conf"
			rm -rf "/etc/upstart/run_patch.conf"
			cp -f "/var/local/kmc/system_patches/run_patch.conf" "/etc/upstart/run_patch.conf"
			chmod 0664 "/etc/upstart/run_patch.conf"
			make_immutable "/etc/upstart/run_patch.conf"
		fi
	fi
fi