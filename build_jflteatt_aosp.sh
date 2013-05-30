#!/bin/sh
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=`readlink -f ..`/Kernel_Stuff/Ramdisks/AOSP_JFLTE
export CONFIG_AOSP_BUILD=y
export PACKAGEDIR=$PARENT_DIR/Kernel_Stuff/Packages_jflteatt/AOSP_JFELTE_ATT
#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm
export CROSS_COMPILE=$PARENT_DIR/linaro4.7/bin/arm-eabi-

time_start=$(date +%s.%N)

echo "Remove old Package Files"
rm -rf $PACKAGEDIR/*

echo "Setup Package Directory"
mkdir -p $PACKAGEDIR/system/lib/modules

echo "Create initramfs dir"
mkdir -p $INITRAMFS_DEST

echo "Remove old initramfs dir"
rm -rf $INITRAMFS_DEST/*

echo "Copy new initramfs dir"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "chmod initramfs dir"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "Remove old zImage"
rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "Make the kernel"
make VARIANT_DEFCONFIG=underwear_jf_att_defconfig SELINUX_DEFCONFIG=jfselinux_defconfig jf_att_defconfig

HOST_CHECK=`uname -n`
if [ $HOST_CHECK = 'ktoonsez-VirtualBox' ] || [ $HOST_CHECK = 'task650-Underwear' ]; then
	echo "Ktoonsez/task650 24!"
	make -j24
else
	echo "Others! - " + $HOST_CHECK
	make -j`grep 'processor' /proc/cpuinfo | wc -l`
fi;

echo "Copy modules to Package"
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules/
cp ../Kernel_Stuff/Ramdisks/libsqlite.so $PACKAGEDIR/system/lib/libsqlite.so

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'console = null androidboot.hardware=qcom user_debug=31 zcache' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $PACKAGEDIR/boot.img 
	export curdate=`date "+%m-%d-%Y"`
	cd $PACKAGEDIR
	cp -R ../META-INF .
	rm ramdisk.gz
	rm zImage
	rm ../Underwear-kernel-jflteatt*.zip
	zip -r ../Underwear-kernel-jflteatt-$curdate.zip .
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

time_end=$(date +%s.%N)
echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"

