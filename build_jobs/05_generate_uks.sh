#!/bin/sh

echo "Extracting + mounting firmware"
${KINDLETOOL} extract cache/firmware.bin build/firmware > "$LOG" 2>&1
gunzip build/firmware/*rootfs*.img.gz
sudo mount -o loop build/firmware/*rootfs*.img build/firmware/mnt

echo "Patching UKS SQSH"
if [ -e  build/firmware/mnt/etc/uks.sqsh ]; then
    sudo mount -o loop build/firmware/mnt/etc/uks.sqsh build/firmware/sqsh_mnt
    cp build/firmware/sqsh_mnt/* build/patched_uks
    sudo umount build/firmware/sqsh_mnt
else
    cp build/firmware/mnt/etc/uks/* build/patched_uks
fi
sudo umount build/firmware/mnt

cat > "build/patched_uks/pubdevkey01.pem" << EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF
mksquashfs build/patched_uks build/kmc/persistence/updater_keys.sqsh > "$LOG"