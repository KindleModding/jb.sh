#!/bin/sh

# On the v2.2.1 payload, 12 MiB retains the size of -9 without its 64 MiB
# decoder dictionary. An 8 MiB dictionary substantially increases base64 size.
xz --lzma2=preset=6,dict=12MiB -c build/kmc.tar > build/kmc.tar.xz || exit 1
kmc_tar=$(base64 -w 0 build/kmc.tar.xz) || exit 1

cat > build/jb.sh <<'HEADER'
#!/bin/sh
rm -rf /tmp/kmc || exit 1
mkdir /tmp/kmc || exit 1
echo "Unpacking JB..."
# Check all pipeline stages, including xz's integrity check, without changing
# shell options for the installation jobs that follow.
if ! (
    set -o pipefail || exit 1
HEADER
printf '    echo "%s" | base64 -d | xz -d | tar xf - -C /tmp/kmc\n' "$kmc_tar" >> build/jb.sh
cat >> build/jb.sh <<'HEADER'
); then
    echo "Payload unpack failed" >&2
    rm -rf /tmp/kmc
    exit 1
fi

# Both platform bundles are packaged. Reject empty/incomplete payloads before
# the installation jobs can remove an existing KMC installation.
for payload_file in kindlepw2/bin/fbink kindlehf/bin/fbink system_patches/patch_system.sh; do
    if [ ! -s "/tmp/kmc/$payload_file" ]; then
        echo "Payload missing required file: $payload_file" >&2
        rm -rf /tmp/kmc
        exit 1
    fi
done
unset payload_file
echo "Done"
HEADER
unset kmc_tar
