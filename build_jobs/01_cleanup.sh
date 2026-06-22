#!/bin/sh

echo "Cleaning up"
set +e
    rm -rf build > "$LOG" 2>&1
    sudo umount build/sqsh_mnt > "$LOG" 2>&1
    sudo umount build/mnt > "$LOG" 2>&1
set -e

echo "Creating folders"
mkdir -p cache
mkdir -p build/firmware/mnt
mkdir -p build/firmware/sqsh_mnt
mkdir -p build/patched_uks
for PLATFORM in kindlepw2 kindlehf
do
    mkdir -p build/kmc/$PLATFORM/bin
    mkdir -p build/kmc/$PLATFORM/lib
done