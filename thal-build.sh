#!/bin/bash
#

START=$(date)

# Initialize all arguments here ...
#
MY_BUILD_DIR=$(pwd)
MY_DEST_DIR=$HOME/Dropbox/N1/kernel
MY_SIGNAPK=$HOME/Dropbox/N1/signapk
MY_ARCH=arm

MY_CC=$HOME/toolchain/ch33kycha1n/arm-eabi-4.7/20111020-2328/bin/arm-eabi-
#MY_CC=$HOME/toolchain/ch33kycha1n/arm-eabi-4.7.0/20110927-1215/bin/arm-eabi-
#MY_CC=$HOME/toolchain/linaro/bin/arm-eabi-

MY_OPTIMIZER="-Ofast"
#MY_OPTIMIZER="-O3"

#MY_KFLAGS="-march=armv7-a -mtune=cortex-a8 -mfpu=neon"
MY_KFLAGS="-march=armv7-a -mtune=cortex-a8 -mfpu=neon -fno-gcse -ffast-math -fsingle-precision-constant -funsafe-loop-optimizations"
VERSION=`cat .config | grep Linux | awk '{print $(5)}'`
echo
echo "Please select ..."
echo "   [1] to load AVS defconfig"
echo "   [2] to load SVS defconfig"
echo "   [Enter} to use existing config"
read choice;
case $choice in
	"1") echo "*** Loading AVS defconfig ...";
	     MY_PREFIX="kernel-oxygeN1zed-avs-$VERSION";
	     make mahimahi_avs_defconfig;;

	"2") echo "*** Loading SVS defconfig ...";
	     MY_PREFIX="kernel-oxygeN1zed-svs-$VERSION";
	     make mahimahi_svs_defconfig;;

        *)   MY_PREFIX="kernel-thalamus-test-$VERSION";;
esac

#git reset --hard
#git pull
echo ""
echo "*** Customizing settings ..."
echo ""
export ARCH=$MY_ARCH
export CROSS_COMPILE=$MY_CC
#sed -i "s/+= -O2/+= $MY_OPTIMIZER/g" Makefile
sed -i 's/ -Werror//g' drivers/net/wireless/bcm4329/Makefile
echo ""
echo "*** Running make clean ..."
echo ""
#make clean
#echo `expr $(date +%Y%m%d) "-" 1` > .version
DTSTAMP=$(date +%Y%m%d%H%M)
echo $DTSTAMP > .version
echo ""
echo "*** Running make ..."
echo ""
export KAFLAGS=$MY_KFLAGS
export KCFLAGS=$MY_KFLAGS
#make -j8 2> error.log
make -j8
if [ -e arch/arm/boot/zImage ]
then
	echo ""
	echo "*** Making external modules"
	echo ""
	#$CROSS_COMPILE"strip" --strip-unneeded -v drivers/net/wireless/bcm4329/bcm4329.ko
	cp -av $MY_DEST_DIR/template-msm $MY_BUILD_DIR/$DTSTAMP
	cp -av arch/arm/boot/zImage $MY_BUILD_DIR/$DTSTAMP/kernel/
	cp -av drivers/net/wireless/bcm4329/bcm4329.ko $MY_BUILD_DIR/$DTSTAMP/system/lib/modules/
	#make modules_install INSTALL_MOD_PATH=./temp
	#cp -av temp/lib/modules/* $MY_BUILD_DIR/$DTSTAMP/system/lib/modules
	#rm -r temp
	#echo ""
	echo "*** Creating signed zip file for recovery ..."
	echo ""
	cd $MY_BUILD_DIR/$DTSTAMP
	echo "ui_print(\"Successfully installed ...\");" >> META-INF/com/google/android/updater-script
	echo "ui_print(\"$MY_PREFIX-$DTSTAMP.zip\");" >> META-INF/com/google/android/updater-script
	zip -rTy $MY_PREFIX-$DTSTAMP.zip *
	java -Xmx512m -jar $MY_SIGNAPK/signapk.jar -w $MY_SIGNAPK/testkey.x509.pem $MY_SIGNAPK/testkey.pk8 $MY_PREFIX-$DTSTAMP.zip ../$MY_PREFIX-$DTSTAMP.zip
	cd $MY_BUILD_DIR
	mv $MY_PREFIX-$DTSTAMP.zip $MY_DEST_DIR/.
	rm -r $DTSTAMP
	echo "";
	echo "[ Build STARTED : $START ]"
	echo "[ Build SUCCESS : $(date) ]"
	echo ""
	echo "[ Recovery zip  : $MY_DEST_DIR/$MY_PREFIX-$DTSTAMP.zip ]"
	echo ""
else
	echo ""
	echo "[ Build STARTED : $START ]"
	echo "[ Build FAILED! : $(date) ]"
	echo ""
fi;

