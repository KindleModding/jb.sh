
echo "Building sh_integration"
cd sh_integration
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf --reconfigure > /dev/null
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel --reconfigure > /dev/null

    echo "- Building armhf"
    meson compile -C builddir_armhf > /dev/null
    echo "- Building armel"
    meson compile -C builddir_armel > /dev/null
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
    meson setup --cross-file ~/x-tools/arm-kindlehf-linux-gnueabihf/meson-crosscompile.txt builddir_armhf --reconfigure -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > /dev/null
    meson setup --cross-file ~/x-tools/arm-kindlepw2-linux-gnueabi/meson-crosscompile.txt builddir_armel --reconfigure -Dtarget=Kindle -Dbitmap=enabled -Ddraw=enabled -Dfonts=enabled -Dimage=enabled -Dinputlib=enabled -Dopentype=enabled -Dfbink=enabled -Dinput_scan=enabled -Dfbdepth=enabled > /dev/null

    echo "- Building armhf"
    meson compile -C builddir_armhf > /dev/null
    echo "- Building armel"
    meson compile -C builddir_armel > /dev/null
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
    make > /dev/null
cd ..
KINDLETOOL="${PWD}/KindleTool/KindleTool/Release/kindletool"