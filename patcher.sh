#!/bin/sh

# Alpine Linux for RasPi Patcher
# Designed for an alpine host!

set -x && \


echo 'Installing dependencies..' && \
apk add cpio curl tar git && \


echo 'Creating jcx/sha file...'
git rev-parse --short | cut -c1-5 > jcx/sha

echo 'Deleting .git...' && \
rm -rf .git

echo 'Downloading alpine...' && \
curl -fSL https://alpine-cf-cdn.jcx.ovh/alpine/v3.11/releases/armhf/alpine-rpi-3.11.6-armhf.tar.gz -o alpine.tar.gz && \

echo 'Extracting initramfs...' && \
( mkdir alpine; cd alpine; tar -xzf ../alpine.tar.gz ) && \
mkdir initramfs && cd initramfs && \
cp ../alpine/boot/initramfs-rpi ./initramfs-rpi.gz && cp ../alpine/boot/initramfs-rpi2 ./initramfs-rpi2.gz && \

echo 'Mounting filesystems...' && \
( mkdir rpi; cd rpi; zcat ../initramfs-rpi.gz | cpio -i ) && \
( mkdir rpi2; cd rpi2; zcat ../initramfs-rpi2.gz | cpio -i ) && \

echo 'Patching Alpine Init script...' && \
( cd rpi; git apply ../../0001-Patch-init.patch ) && \
( cd rpi2; git apply ../../0001-Patch-init.patch ) && \

echo 'Injecting custom data...' && \
( chmod -R 777 ../jcx ) && \
( cd rpi; cp -r ../../jcx ./ ) && \
( cd rpi2; cp -r ../../jcx ./ ) && \

echo 'Adding usercfg.txt...' && \
( cd ../alpine; cp ../usercfg.txt ./ )

# ./patcher debug | override cmdline.txt to include non-quiet and serial UART console
if [ $1 == 'debug' ]
then
	echo 'Adding cmdline.txt (debug mode)'
	( cd ../alpine; mv cmdline.txt cmdline.txt.vanilla; cp ../cmdline.txt ./)
else
	echo "Debug not set, skipping cmdline.txt..."
fi

echo 'Repacking Alpine...' && \
( cd rpi; find . | cpio -H newc -o | gzip -9 > ../initramfs-rpi-patched ) && \
( cd rpi2; find . | cpio -H newc -o | gzip -9 > ../initramfs-rpi2-patched ) && \

echo 'Injecting patched filesystem into boot...' && \
cd ../alpine/ && \
cp ../initramfs/initramfs-rpi-patched ./boot/initramfs-rpi && \
cp ../initramfs/initramfs-rpi2-patched ./boot/initramfs-rpi2 && \
tar -zcvf ../alpine-patched.tar.gz ./
