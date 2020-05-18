#!/bin/sh

echo "[JCX First Boot Service]" > /dev/console

set -x

PREFIX=
. $PREFIX/lib/libalpine.sh

if [ "$rc_sys" != LXC ]; then
	$PREFIX/sbin/setup-keymap gb gb
	$PREFIX/sbin/setup-hostname alpine
fi

#if [ -n "$INTERFACESOPTS" ]; then
#	printf "$INTERFACESOPTS" | $PREFIX/sbin/setup-interfaces -i
#else
#	$PREFIX/sbin/setup-interfaces ${quick:+-a}
#fi
#$PREFIX/sbin/setup-interfaces
echo "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
	hostname alpine
" | $PREFIX/sbin/setup-interfaces -i

# start the networking
/etc/init.d/networking --quiet start >/dev/null

# setup up dns if no dhcp was configured
#grep '^iface.*dhcp' $ROOT/etc/network/interfaces > /dev/null ||\
#	$PREFIX/sbin/setup-dns ${DNSOPTS}

# ---- SKIP ROOT PASSWORD SETTING ----

# Setup timezone
$PREFIX/sbin/setup-timezone -z Europe/London

# Enable services

rc-update --quiet add networking boot
rc-update --quiet add urandom boot
for svc in acpid cron crond; do
	if rc-service --exists $svc; then
		rc-update --quiet add $svc
	fi
done

# enable new hostname
/etc/init.d/hostname --quiet restart

# start up the services
openrc boot
openrc default

# update /etc/hosts - after we have got dhcp address
# Get default fully qualified domain name from *first* domain
# given on *last* search or domain statement.
_dn=$(sed -n \
-e '/^domain[[:space:]][[:space:]]*/{s///;s/\([^[:space:]]*\).*$/\1/;h;}' \
-e '/^search[[:space:]][[:space:]]*/{s///;s/\([^[:space:]]*\).*$/\1/;h;}' \
-e '${g;p;}' /etc/resolv.conf 2>/dev/null)

_hn=$(hostname)
_hn=${_hn%%.*}

sed -i -e "s/^127\.0\.0\.1.*/127.0.0.1\t${_hn}.${_dn:-$(get_fqdn)} ${_hn} localhost.localdomain localhost/" /etc/hosts


# ----- SKIPPING PROXY -----

# Setup NTP
if ! is_qemu && [ "$rc_sys" != "LXC" ] && [ "$quick" != 1 ]; then
	# OpenNTPD is lighter, but doesn't seem to work.
	$PREFIX/sbin/setup-ntp -c chrony
fi

# Setup APK Repo Opts ------ SKIPPED
# $PREFIX/sbin/setup-apkrepos ${APKREPOSOPTS}

# Setup SSHD
$PREFIX/sbin/setup-sshd -c openssh

# Enable password and root login.
echo -e "PasswordAuthentication yes\nPermitRootLogin yes\nPermitEmptyPasswords yes\nDenyUsers guest" > /etc/ssh/sshd_config
rc-service sshd restart

# misc
if is_xen_dom0; then
	setup-xen-dom0
fi

if [ "$rc_sys" = "LXC" ]; then
	exit 0
fi

# Disk stuff

# ----- Create ext4 filesystem on the card's extra space -----

apk add --no-cache --virtual jcxformat --force-non-repository parted e2fsprogs

START=$(parted -s /dev/mmcblk0 unit MB print free | tail -n2 | head -n1 | awk '{print $1}')

END=$(parted -s /dev/mmcblk0 unit MB print free | tail -n2 | head -n1 | awk '{print $2}')

SIZE=$(parted -s /dev/mmcblk0 unit MB print free | tail -n2 | head -n1 | awk '{print $3}')

echo -e Start: $START\\nEnd: $END\\nSize: $SIZE

parted -s /dev/mmcblk0 mkpart primary ext4 $START $END


# Not required, parted will do this automatically
# mkfs.ext4 /dev/mmcblk0p2

mkdir -p /media/mmcblk0p2

echo "/dev/mmcblk0p2 /media/mmcblk0p2 ext4 rw,relatime,errors=remount-ro 0 0" >> /etc/fstab

mount /dev/mmcblk0p2

apk del jcxformat

# ----- END -----

DEFAULT_DISK=none \
	#$PREFIX/sbin/setup-disk -q ${DISKOPTS} || exit
	# default rpi sd card
	$PREFIX/sbin/setup-disk -q -m data /media/mmcblk0p2/data || exit

diskmode=$(cat /tmp/alpine-install-diskmode.out 2>/dev/null)

# setup lbu and apk cache unless installed sys on disk
if [ "$diskmode" != "sys" ]; then
	#$PREFIX/sbin/setup-lbu ${LBUOPTS}
	# default rpi sd card
	$PREFIX/sbin/setup-lbu mmcblk0p2
	#$PREFIX/sbin/setup-apkcache ${APKCACHEOPTS}
	# default rpi sd card
	$PREFIX/sbin/setup-apkcache /media/mmcblk0p2/cache
	if [ -L /etc/apk/cache ]; then
		apk cache sync
	fi
fi

# Upgrade all packages
apk update && apk upgrade

# Enable /jcx/checks for LBU
lbu add /jcx/checks
lbu add /jcx/checks/*

# Touch the check file and exit
mkdir -p /jcx/checks
touch /jcx/checks/firstboot

exit 0
