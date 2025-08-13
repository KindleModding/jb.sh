#!/bin/sh

# Kindlet JB doesn't match, install it
if [ "$(md5sum "/opt/amazon/ebook/lib/json_simple-1.1.jar" | cut -d' ' -f1)" != "$(md5sum "/var/local/kmc/persistence/json_simple-1.1.jar" | cut -d' ' -f1)" ] ; then
	logmsg "I" "install_mkk_kindlet_jb" "" "Copying the kindlet jailbreak"
	cp -f "/var/local/kmc/persistence/json_simple-1.1.jar" "/opt/amazon/ebook/lib/json_simple-1.1.jar"
	chmod 0664 "/opt/amazon/ebook/lib/json_simple-1.1.jar"
fi