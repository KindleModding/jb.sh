#!/bin/sh

echo "Building sh_integration"
cd sh_integration
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf --reconfigure --buildtype=release > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel --reconfigure --buildtype=release > "$LOG"

    echo "- Building armhf"
    meson compile -C builddir_armhf > "$LOG"
    echo "- Building armel"
    meson compile -C builddir_armel > "$LOG"
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
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf --reconfigure --buildtype=release -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel --reconfigure --buildtype=release -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > "$LOG"

    echo "- Building armhf"
    meson compile -C builddir_armhf > "$LOG"
    echo "- Building armel"
    meson compile -C builddir_armel > "$LOG"
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
    make > "$LOG"
cd ..
KINDLETOOL="${PWD}/KindleTool/KindleTool/Release/kindletool"