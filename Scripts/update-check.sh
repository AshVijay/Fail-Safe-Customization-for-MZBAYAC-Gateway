#!/bin/bash

updateStatus=$(cat /etc/update-status)

if [ $updateStatus -eq 1 ]; then

	mount /dev/mmcblk0p5 /mnt > /dev/null 2>&1
	cur_kernel=$(ls /mnt/boot | grep vmlinuz)
	cur_initrd=$(ls /mnt/boot | grep initrd)
	new_kernel=$(ls /boot | grep vmlinuz)
	new_initrd=$(ls /boot | grep initrd)
	cur_ver=$(echo ${cur_kernel:8:8})
	new_ver=$(echo ${new_kernel:8:8})
	echo "$cur_ver"
	echo "$new_ver"
	rm /mnt/boot/$cur_kernel > /dev/null 2>&1
	rm /mnt/boot/$cur_initrd > /dev/null 2>&1
	cp /boot/$new_kernel /mnt/boot/$new_kernel
	cp /boot/$new_initrd /mnt/boot/$new_initrd
	chmod 600 /mnt/boot/$new_kernel
	chmod 644 /mnt/boot/$new_initrd
	sed -i -e "s/$cur_ver/$new_ver/g" /boot/grub/grub.cfg
	umount /mnt > /dev/null 2>&1
	echo 0 > /etc/update-status
	echo 0 > /etc/firmware-update-status
	sync
	echo "Done"
	reboot
fi

exit 0
