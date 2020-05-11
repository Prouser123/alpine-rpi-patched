#!/bin/sh

echo "[JCX Boot Service]" > /dev/console

# If first boot, run setup.
echo "[JCX Boot Service] Checking if this is the first boot..."
if [ ! -e /jcx/checks/firstboot ]
then
	echo "[JCX Boot Service] First boot! Running setup..."
	sh /jcx/services/boot/setup-runner
fi

echo "[JCX Boot Service] Done!"

exit 0