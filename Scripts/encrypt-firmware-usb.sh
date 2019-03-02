#!/bin/bash

echo "Encrypting & Copying Firmware from $1 to USB..."

umount "$2" > /dev/null 2>&1
mount "$2" /mnt > /dev/null 2>&1
rm -rf /mnt/crypted > /dev/null 2>&1
mkdir -p /mnt/crypted

echo "19239123841" | ecryptfs-add-passphrase --fnek > /dev/null 2>&1
mount -i -t ecryptfs /mnt/crypted/ /mnt/crypted/ -o ecryptfs_sig=faa2eb740f201c8d,ecryptfs_fnek_sig=5ac0db675b79d628,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1

sleep 1

umount /mnt/crypted > /dev/null 2>&1
sync

echo "19239123841" | ecryptfs-add-passphrase --fnek > /dev/null 2>&1
mount -i -t ecryptfs /mnt/crypted/ /mnt/crypted/ -o ecryptfs_sig=faa2eb740f201c8d,ecryptfs_fnek_sig=5ac0db675b79d628,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1

touch /mnt/crypted/authorised
touch /mnt/crypted/app_update
chmod 644 /mnt/crypted/authorised
chmod 644 /mnt/crypted/app_update
echo 1 > /mnt/crypted/authorised
echo 1 > /mnt/crypted/app_update

echo "Copying firmware files into USB..."
cp -r "$1"* /mnt/crypted

umount /mnt/crypted > /dev/null 2>&1
umount /mnt > /dev/null 2>&1
sync

echo "Done"

exit 0
