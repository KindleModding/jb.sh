#!/bin/sh
# Todo: turn this whole thing into a bind mount, should be ezpz
# Kindlet JB doesn't match, install it
if [ "$(md5sum "/opt/amazon/ebook/lib/json_simple-1.1.jar" | cut -d' ' -f1)" != "$(md5sum "/var/local/kmc/system_patches/json_simple-1.1.jar" | cut -d' ' -f1)" ] ; then
	log "Copying the kindlet jailbreak"
	setup_bind_mount /opt/amazon/ebook/lib/json_simple-1.1.jar
	cp -f "/var/local/kmc/system_patches/json_simple-1.1.jar" "/var/local/kmc/binds/opt/amazon/ebook/lib/json_simple-1.1.jar"
	chmod 0664 "/opt/amazon/ebook/lib/json_simple-1.1.jar"
fi