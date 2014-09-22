#!/bin/bash

set -o nounset
set -o errexit

# config
zipfile="xluco-smp600.zip"

# functions start
InitialCleanup() {
    echo "=> Initial cleanup"
    if [ -e $zipfile ]; then rm -f $zipfile; echo " >>>Removing old zip"; fi;
    FinalCleanup
}

MakeKernel() {
    echo "=> Building Kernel"
    cd ../kernel_smp600
    export USE_CCACHE=1
    export CCACHE_COMPILERCHECK=content
    export INSTALL_MOD_STRIP=1
    make mrproper
    make xluco_defconfig
    make -j5
    cd ../build_smp600
}

MakeRamdisk() {
    echo "=> Packing the ramdisk"
    ./mkbootfs ../ramdisk_smp600 | xz -6 -Ccrc32 > ramdisk.xz
}

MakeBootImg() {
    echo "=> Making boot.img"
    cp ../kernel_smp600/arch/arm/boot/zImage .
    ./mkbootimg --kernel zImage --ramdisk ramdisk.xz -o boot.img
}

MakeZip() {
    echo "=> Making zip"
    mv boot.img ./zip/
    cd zip/
    zip -r -9 $zipfile *
    mv $zipfile ../
    cd ..
}

FinalCleanup() {
    if [ -e zip/boot.img ]; then rm -f zip/boot.img; echo " >>>Removing old boot.img"; fi;
    if [ -e ramdisk.xz ]; then rm -f ramdisk.xz; echo " >>>Removing old ramdisk"; fi;
    if [ -e zImage ]; then rm -f zImage; echo " >>>Removing old zImage"; fi;
}
# functions end

STARTTIME=$(date +%s.%N)
InitialCleanup
MakeKernel
MakeRamdisk
MakeBootImg
MakeZip
echo "=> Final cleanup"
FinalCleanup
ENDTIME=$(date +%s.%N)
ELAPSEDTIME=$(echo "$ENDTIME - $STARTTIME" | bc)
echo "=> Done in $ELAPSEDTIME seconds!"
exit 0
