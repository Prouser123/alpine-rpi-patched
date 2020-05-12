#!/bin/sh

echo "[JCX Boot Service] Welcome!" > /dev/console

# If first boot, run setup.
echo "[JCX Boot Service] Checking if this is the first boot..."
if [ ! -e /jcx/checks/firstboot ]
then
	echo "[JCX Boot Service] First boot! Running setup..."
	sh /jcx/services/boot/setup-runner
fi

# ----- System Information -----

echo ""
echo -e "\033[1;32mModel\t\t\033[1;36m$(cat /proc/device-tree/model)\033[0m"

# get OS release name and version id, running in isolated shell.
(. /etc/os-release; echo -e "\033[1;32mOS Release\t\033[1;36m$NAME v$VERSION_ID\033[0m" )
echo -e "\033[1;32m$(uname -s)\t\t\033[1;36m$(uname -r) ($(uname -m))\033[0m"
echo -e "\033[1;32mTotal RAM\t\033[1;36m$(grep "MemTotal" /proc/meminfo | awk '{print $2}')kB (base 10)\033[0m"
echo -e "\033[1;32mIP (eth0)\t\033[1;36m$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | cut -d ' ' -f1)\033[0m"
echo -e "\033[1;32mSHA\t\t\033[1;36m$(cat /jcx/.sha)\033[0m"

echo ""

echo -e "\033[1;35mAPK \033[1;32mInstalled\t\t\033[1;36m$(apk list -I | tee /dev/null | wc -l)\033[0m"
echo -e "\033[1;35mAPK \033[1;32mAvailable (boot)\t\033[1;36m$(apk list -a --repositories-file /media/mmcblk0p1/apks/ | tee /dev/null | wc -l)\033[0m"
echo -e "\033[1;35mAPK \033[1;32mAvailable\t\t\033[1;36m$(apk list -a | tee /dev/null | wc -l)\033[0m"

echo ""

df -h

echo ""

# ----- System Information END -----

echo "[JCX Boot Service] Done!"

exit 0