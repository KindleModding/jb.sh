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
for ARCH in armel armhf
do
    mkdir -p build/kmc/$ARCH/bin
    mkdir -p build/kmc/$ARCH/lib
done