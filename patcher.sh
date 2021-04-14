#!/bin/sh

# Alpine Linux for RasPi Patcher
# Designed for an alpine host!

set -x && \


echo 'Installing dependencies..' && \
apk add cpio curl tar git && \


echo 'Creating jcx/sha file...'
git rev-parse --short HEAD > jcx/sha

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

echo 'Downloading and extracting extra packages (coreutils)...' && \
(
	mkdir -p /tmp/coreutils-stuffs && cd /tmp/coreutils-stuffs
	curl -fSL --create-dirs --output-dir apks/ \
	-O https://alpine-cf-cdn.jcx.ovh/alpine/v3.11/main/armhf/coreutils-8.31-r0.apk \
	-O https://alpine-cf-cdn.jcx.ovh/alpine/v3.11/main/armhf/libacl-2.2.53-r0.apk \
	-O https://alpine-cf-cdn.jcx.ovh/alpine/v3.11/main/armhf/libattr-2.4.48-r0.apk

	mkdir fs && cd fs

	# 1: Extract coreutils
	tar -xvf ../apks/coreutils-8.31-r0.apk usr/bin/coreutils usr/bin/stdbuf usr/libexec/coreutils/libstdbuf.so
	tar -xvf ../apks/libacl-2.2.53-r0.apk lib/libacl.so.1 lib/libacl.so.1.1.2253
	tar -xvf ../apks/libattr-2.4.48-r0.apk lib/libattr.so.1 lib/libattr.so.1.1.2448
)

echo 'Packing extra packages...' && \
(
	mkdir -p ../alpine/apks/extra-fs/
	cd ../alpine/apks/extra-fs/
	tar -zcvf coreutils.fs.tar.gz -C /tmp/coreutils-stuffs/fs/ .

	chmod -R 755 ./
)


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
