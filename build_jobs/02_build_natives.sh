#!/bin/sh

echo "Building sh_integration"
cd sh_integration
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_kindlehf --reconfigure --buildtype=release > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_kindlepw2 --reconfigure --buildtype=release > "$LOG"

    echo "- Building kindlehf"
    meson compile -C builddir_kindlehf > "$LOG"
    echo "- Building kindlepw2"
    meson compile -C builddir_kindlepw2 > "$LOG"
    echo "- Copying sh_integration"
    for PLATFORM in kindlepw2 kindlehf
    do
        cp -f "builddir_${PLATFORM}/extractor/sh_integration_extractor.so" "../build/kmc/${PLATFORM}/lib/"
        cp -f "builddir_${PLATFORM}/launcher/sh_integration_launcher" "../build/kmc/${PLATFORM}/bin/"
    done
cd ..

echo "Building FBInk"
cp fbink_patch/* FBInk/
cd FBInk
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_kindlehf --reconfigure --buildtype=release -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_kindlepw2 --reconfigure --buildtype=release -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > "$LOG"

    echo "- Building kindlehf"
    meson compile -C builddir_kindlehf > "$LOG"
    echo "- Building kindlepw2"
    meson compile -C builddir_kindlepw2 > "$LOG"
    echo "- Copying FBInk"
    for PLATFORM in kindlepw2 kindlehf
    do
        cp -f "builddir_${PLATFORM}/libfbink_input.so" "../build/kmc/${PLATFORM}/lib/"
        cp -f "builddir_${PLATFORM}/libfbink.so" "../build/kmc/${PLATFORM}/lib/"
        cp -f "builddir_${PLATFORM}/input_scan" "../build/kmc/${PLATFORM}/bin/"
        cp -f "builddir_${PLATFORM}/fbink" "../build/kmc/${PLATFORM}/bin/"
        cp -f "builddir_${PLATFORM}/fbdepth" "../build/kmc/${PLATFORM}/bin/"
    done
cd ..

echo "Building KPM"
cd KPM
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_kindlehf --reconfigure --buildtype=release > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_kindlepw2 --reconfigure --buildtype=release > "$LOG"

    echo "- Building kindlehf"
    meson compile -C builddir_kindlehf > "$LOG"
    echo "- Building kindlepw2"
    meson compile -C builddir_kindlepw2 > "$LOG"
    echo "- Copying KPM"
    for PLATFORM in kindlepw2 kindlehf
    do
        cp -f "builddir_${PLATFORM}/src/libkpm.so" "../build/kmc/${PLATFORM}/lib/"
        cp -f "builddir_${PLATFORM}/cli/kpm" "../build/kmc/${PLATFORM}/bin/"
    done
cd ..

echo "Building KMC System Patcher"
cd system_patcher
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_kindlehf --reconfigure --buildtype=release > "$LOG"
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_kindlepw2 --reconfigure --buildtype=release > "$LOG"

    echo "- Building kindlehf"
    meson compile -C builddir_kindlehf > "$LOG"
    echo "- Building kindlepw2"
    meson compile -C builddir_kindlepw2 > "$LOG"
    echo "- Copying KPM"
    for PLATFORM in kindlepw2 kindlehf
    do
        cp -f "builddir_${PLATFORM}/kmc_system_patcher" "../build/kmc/${PLATFORM}/bin/"
    done
cd ..

echo "Building KindleTool"
cd KindleTool
    make > "$LOG"
cd ..
KINDLETOOL="${PWD}/KindleTool/KindleTool/Release/kindletool"