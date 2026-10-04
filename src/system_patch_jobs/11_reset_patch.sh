#!/bin/sh

log "Patching factory reset script"

if [ ! -f /usr/sbin/factory_reset.bck ]; then
    cp /usr/sbin/factory_reset /usr/sbin/factory_reset.bck
fi

echo "#!/bin/sh" > /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
echo "if [ -f /var/local/kmc/sbin/kmc_reset.sh ]; then" >> /usr/sbin/factory_reset
echo "    sh /var/local/kmc/sbin/kmc_reset.sh" >> /usr/sbin/factory_reset
echo "fi" >> /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
cat /usr/sbin/factory_reset.bck >> /usr/sbin/factory_reset