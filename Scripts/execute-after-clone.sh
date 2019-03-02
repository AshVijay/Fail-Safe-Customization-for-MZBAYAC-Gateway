#!/bin/bash

string=$(ifconfig wlp2s0 | grep HWaddr)
#echo "$string"

MAC_DIGIT_12=$(echo ${string:50:2})
MAC_DIGIT_34=$(echo ${string:53:2})

#echo "$MAC_DIGIT_12"
#echo "$MAC_DIGIT_34"

MAC="$MAC_DIGIT_12$MAC_DIGIT_34"
MAC=$(echo "${MAC^^}")
echo "$MAC"

cur_val="XXXX"
#cat /etc/hostapd/hostapd.conf
systemctl stop hostapd.service
sed -i -e "s/$cur_val/$MAC/g" /etc/hostapd/hostapd.conf
#cat /etc/hostapd/hostapd.conf
systemctl start hostapd.service

# Update Bootloader

echo "Reinstalling GRUB"

apt-get install --reinstall grub-efi -y
grub-install /dev/mmcblk0
rm /boot/efi/EFI/ubuntu/*.efi
cp /boot/efi/EFI/ubuntu/custom/*.efi /boot/efi/EFI/ubuntu/

echo "Done"

#reboot

exit 0
