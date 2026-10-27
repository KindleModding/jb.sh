#!/bin/sh

###
# I'm tired of useless logs
###

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

STAGE_DIR="/tmp/kmc_log"
rm -rf "$STAGE_DIR" /tmp/kmc_log.tar.gz /mnt/us/documents/kmc_log 2>/dev/null || true
mkdir -p "$STAGE_DIR"

[ -d /var/local/log ] && cp -r /var/local/log "$STAGE_DIR/" 2>/dev/null || true
LOG_PATH="$STAGE_DIR/kmc_log.txt"

echo "====================" > "$LOG_PATH"
echo "=   START KMC LOG  =" >> "$LOG_PATH"
echo "====================" >> "$LOG_PATH"
echo "Timestamp: $(date 2>/dev/null)" >> "$LOG_PATH"
echo "Uptime: $(cat /proc/uptime 2>/dev/null)" >> "$LOG_PATH"

echo >> "$LOG_PATH"
echo "===> Bounded Directory Listings" >> "$LOG_PATH"
ls -la /mnt/us /mnt/us/documents /var/local /var/local/kmc /var/local/xm >> "$LOG_PATH" 2>&1 || true

echo >> "$LOG_PATH"
echo "===> /var/local/kmc contents" >> "$LOG_PATH"
find /var/local/kmc -maxdepth 3 -exec md5sum {} \; >> "$LOG_PATH" 2>/dev/null || true

echo >> "$LOG_PATH"
echo "===> /var/local/mkk contents" >> "$LOG_PATH"
find /var/local/mkk -maxdepth 2 -exec md5sum {} \; >> "$LOG_PATH" 2>/dev/null || true

echo >> "$LOG_PATH"
echo "===> /mnt/us/kmc contents" >> "$LOG_PATH"
find /mnt/us/kmc -maxdepth 3 -exec md5sum {} \; >> "$LOG_PATH" 2>/dev/null || true

echo "====================" >> "$LOG_PATH"
echo "=    THANK YOU.    =" >> "$LOG_PATH"
echo "=   END KMC LOG  =" >> "$LOG_PATH"
echo "====================" >> "$LOG_PATH"

cp -f /etc/version.txt "$STAGE_DIR/" 2>/dev/null || true
cp -f /etc/prettyversion.txt "$STAGE_DIR/" 2>/dev/null || true

cp -f /var/log/messages "$STAGE_DIR/var_log_messages" 2>/dev/null || true
dmesg > "$STAGE_DIR/dmesg" 2>/dev/null || true

cp -f /var/local/appreg.db "$STAGE_DIR/" 2>/dev/null || true
cp -f /var/local/cc.db "$STAGE_DIR/" 2>/dev/null || true
cp -f /var/local/deviceType.txt "$STAGE_DIR/" 2>/dev/null || true
cp -f /mnt/us/kmc/kpm/kpm.db "$STAGE_DIR/" 2>/dev/null || true
cp -f /var/local/kmc/boot.log "$STAGE_DIR/" 2>/dev/null || true
cp -f /var/local/kmc/boot-timeout-diag.txt "$STAGE_DIR/" 2>/dev/null || true

tar czf /tmp/kmc_log.tar.gz -C /tmp kmc_log 2>/dev/null || tar czf /tmp/kmc_log.tar.gz "$STAGE_DIR" 2>/dev/null || true
mkdir -p /mnt/us/documents 2>/dev/null || true
rm -f /mnt/base-us/documents/kmc_log.tar.gz /mnt/us/documents/kmc_log.tar.gz 2>/dev/null || true
cp -f /tmp/kmc_log.tar.gz /mnt/us/documents/kmc_log.tar.gz 2>/dev/null || true
rm -rf "$STAGE_DIR" /tmp/kmc_log.tar.gz 2>/dev/null || true
sync

if [ -x /var/local/kmc/bin/fbink ]; then
    /var/local/kmc/bin/fbink -y 2 -m "KMC log saved to documents/kmc_log.tar.gz" >/dev/null 2>&1 || true
elif command -v eips_v2 >/dev/null 2>&1; then
    eips_v2 text "KMC log saved to documents/kmc_log.tar.gz" --top 24 >/dev/null 2>&1 || true
fi