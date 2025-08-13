#!/bin/sh

# Check if we need to do something with the Kindlet developer keystore
# No developer keystore, install it                       		OR  The developer keystore doesn't match - NOTE: This *will* mess with real, official developer keystores. Not that we really care about it, but it should be noted ;).
if [ ! -f "/var/local/java/keystore/developer.keystore" ] || \
	[ "$(md5sum "/var/local/java/keystore/developer.keystore" | cut -d' ' -f1)" != "$(md5sum "/var/local/kmc/persistence/developer.keystore" | cut -d' ' -f1)" ] ; then
	
	# Install the kindlet keystore
	log "Copying the kindlet keystore"
	# We shouldn't need to do anything specific to read/write /var/local
	if [ "$(df -k /var/local | tail -n 1 | tr -s ' ' | cut -d' ' -f4)" -lt "512" ] ; then
		# Hu ho... Keep track of this...
		VARLOCAL_OOS="true"
		log "Failed to copy the kindlet keystore: not enough space left on device"
		# THIS SHOULD NOT BE POSSIBLE???
	else
		# NOTE: This might have gone poof on newer devices without Kindlet support, so, create it as needed
		mkdir -p "/var/local/java/keystore"
		cp -f "/var/local/kmc/persistence/developer.keystore" "/var/local/java/keystore/developer.keystore"
	fi

	# Show some feedback
	print_mkk_dev_keystore_feedback
fi