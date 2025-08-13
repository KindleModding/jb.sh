#!/bin/sh
set -e

echo "Monolithic jb.sh Builder"
echo "Created by HackerDude"
echo "v1.0.0"
echo

echo "Checking system"


echo "Cleaning up"
set +e
    rm -rf build
    rm -rf sh_integration/builddir_*
    rm -rf FBInk/builddir_*
    sudo umount build/sqsh_mnt
    sudo umount build/mnt
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

echo "Building sh_integration"
cd sh_integration
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel

    echo "- Building armhf"
    meson compile -C builddir_armhf
    echo "- Building armel"
    meson compile -C builddir_armel
    echo "- Copying sh_integration"
    for ARCH in armel armhf
    do
        cp -f "builddir_${ARCH}/extractor/sh_integration_extractor.so" "../build/kmc/${ARCH}/lib/"
        cp -f "builddir_${ARCH}/launcher/sh_integration_launcher" "../build/kmc/${ARCH}/bin/"
    done
cd ..

echo "Building FBInk"
cp fbink_patch/* FBInk/
cd FBInk
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled

    echo "- Building armhf"
    meson compile -C builddir_armhf
    echo "- Building armel"
    meson compile -C builddir_armel
    echo "- Copying FBInk"
    for ARCH in armel armhf
    do
        cp -f "builddir_${ARCH}/libfbink_input.so" "../build/kmc/${ARCH}/lib/"
        cp -f "builddir_${ARCH}/libfbink.so" "../build/kmc/${ARCH}/lib/"
        cp -f "builddir_${ARCH}/input_scan" "../build/kmc/${ARCH}/bin/"
        cp -f "builddir_${ARCH}/fbink" "../build/kmc/${ARCH}/bin/"
        cp -f "builddir_${ARCH}/fbdepth" "../build/kmc/${ARCH}/bin/"
    done
cd ..

#echo "Building KMRP"
# @TODO

echo "Building KindleTool"
cd KindleTool
    make
cd ..
KINDLETOOL="${PWD}/KindleTool/KindleTool/Release/kindletool"



echo "Downloading firmware"
if command -v aria2c >/dev/null 2>&1
then
    aria2c -c -s 16 -x 16 -k 2M "https://www.amazon.com/update_Kindle_Oasis_10th_Gen" -o "cache/firmware.bin"
else
    curl --progress-bar -L -C - -o "cache/firmware.bin" "https://www.amazon.com/update_Kindle_Oasis_10th_Gen"
fi

echo "Extracting + mounting firmware"
${KINDLETOOL} extract cache/firmware.bin build/firmware
gunzip build/firmware/*rootfs*.img.gz
sudo mount -o loop build/firmware/*rootfs*.img build/firmware/mnt

echo "Patching UKS SQSH"
if [ -e  build/firmware/mnt/etc/uks.sqsh ]; then
    sudo mount -o loop build/firmware/mnt/etc/uks.sqsh build/firmware/sqsh_mnt
    cp build/firmware/sqsh_mnt/* build/patched_uks
    sudo umount build/firmware/sqsh_mnt
    sudo umount build/firmware/mnt
else
    cp build/firmware/mnt/etc/uks/* build/patched_uks
fi

cat > "build/patched_uks/pubdevkey01.pem" << EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF
mksquashfs build/patched_uks build/kmc/updater_keys.sqsh

echo "Packing KMC directory"
tar -cf ./build/kmc.tar -C ./build/kmc/ .