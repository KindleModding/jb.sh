#!/bin/sh

if [ $ROOTLESS -eq 1 ]; then
    setup_bind_mount /usr/sbin # patching mntroot is too important to skip patching it on rootless systems, so no size check here
    # So no one runs a rogue scriptlet and immediately kills their device:
    if [ -f /usr/sbin/mntroot ]; then
        ln -sf /dev/null /usr/sbin/mntroot
        log "mntroot patched to /dev/null"
    fi
fi

log "Patching factory reset script"
cp /usr/sbin/factory_reset /usr/sbin/factory_reset.bck
echo "#!/bin/sh" > /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
echo "if [ -f /var/local/kmc/sbin/kmc_reset.sh ]; then" >> /usr/sbin/factory_reset
echo "    sh /var/local/kmc/sbin/kmc_reset.sh" >> /usr/sbin/factory_reset
echo "fi" >> /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
cat /usr/sbin/factory_reset.bck >> /usr/sbin/factory_reset


make_immutable /var/local/kmc