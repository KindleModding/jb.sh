#!/bin/sh
# This can probably just be turned into a bind mount
log "Patching factory reset script"

if [ $ROOTLESS -eq 1 ]; then
    dir_size=$(du -sk "/usr/sbin" | cut -f1)
    if [ "$dir_size" -gt "$MAX_COPY_SIZE" ]; then
        log "/usr/sbin is too large to patch the factory reset script, skipping." # usually 3.5mb, so our 5mb limit should be fine here
        continue
    fi
    setup_bind_mount /usr/sbin
fi

if [ $ROOTLESS -eq 0 ]; then
    if [ ! -f /usr/sbin/factory_reset.bck ]; then
        cp /usr/sbin/factory_reset /usr/sbin/factory_reset.bck
    fi # not necessary on rootless systems
fi

echo "#!/bin/sh" > /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
echo "if [ -f /var/local/kmc/sbin/kmc_reset.sh ]; then" >> /usr/sbin/factory_reset
echo "    sh /var/local/kmc/sbin/kmc_reset.sh" >> /usr/sbin/factory_reset
echo "fi" >> /usr/sbin/factory_reset
echo "" >> /usr/sbin/factory_reset
cat /usr/sbin/factory_reset.bck >> /usr/sbin/factory_reset

make_immutable /var/local/kmc