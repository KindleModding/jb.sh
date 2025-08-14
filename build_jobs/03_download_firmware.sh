#!/bin/sh

echo "Downloading firmware"
if command -v aria2c >"$LOG" 2>&1
then
    aria2c -c -s 16 -x 16 -k 2M "https://www.amazon.com/update_Kindle_Oasis_10th_Gen" -o "cache/firmware.bin" > "$LOG"
else
    curl --progress-bar -L -C - -o "cache/firmware.bin" "https://www.amazon.com/update_Kindle_Oasis_10th_Gen" > "$LOG"
fi