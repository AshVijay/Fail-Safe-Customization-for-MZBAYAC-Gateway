#!/bin/bash

bak_kernel_file=$(ls /boot | grep vmlinuz)
bak_initrd_file=$(ls /boot | grep initrd)
bak_kern_ver=$(echo ${bak_kernel_file:8:8})

echo $bak_kern_ver

mount /dev/mmcblk0p2 /mnt > /dev/null 2>&1

kernel_file=$(ls /mnt/boot | grep vmlinuz)
kern_ver=$(echo ${kernel_file:8:8})
echo $kern_ver

rm /mnt/boot/vmlinuz* > /dev/null 2>&1
rm /mnt/boot/initrd* > /dev/null 2>&1
cp /boot/$bak_kernel_file /mnt/boot/$bak_kernel_file
cp /boot/$bak_initrd_file /mnt/boot/$bak_initrd_file
chmod 600 /mnt/boot/$bak_kernel_file
chmod 644 /mnt/boot/$bak_initrd_file

if [ $(cat /mnt/etc/update-status) -eq 1 ]; then
	sed -i -e "s/$kern_ver/$bak_kern_ver/g" /mnt/boot/grub/grub.cfg
	echo 0 > /mnt/etc/update-status
fi

sync
umount /mnt > /dev/null 2>&1
echo "Done"
reboot

exit 0
