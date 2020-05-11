#!/bin/sh

echo "[JCX Boot Service]" > /dev/console

echo "[JCX Entrypoint] Checking if this is the first boot..."
if [[ ! -f /jcx/checks/firstboot ]]
then
	echo "[JCX Entrypoint] First boot! Running setup..."
	sh /jcx/services/boot/setup-runner
fi

echo "[JCX Boot Service] Done!"

exit 0