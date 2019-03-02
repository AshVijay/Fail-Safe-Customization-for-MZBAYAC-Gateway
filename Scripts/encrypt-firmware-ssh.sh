#!/bin/bash

echo "Encrypting Firmware in $1..."

rm -rf ./crypted/ > /dev/null 2>&1
mkdir -p ./crypted

echo "19239123841" | ecryptfs-add-passphrase --fnek > /dev/null 2>&1
mount -i -t ecryptfs ./crypted/ ./crypted/ -o ecryptfs_sig=faa2eb740f201c8d,ecryptfs_fnek_sig=5ac0db675b79d628,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1

sleep 1

umount ./crypted > /dev/null 2>&1
sync

echo "19239123841" | ecryptfs-add-passphrase --fnek > /dev/null 2>&1
mount -i -t ecryptfs ./crypted/ ./crypted/ -o ecryptfs_sig=faa2eb740f201c8d,ecryptfs_fnek_sig=5ac0db675b79d628,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1

touch ./crypted/authorised
touch ./crypted/app_update
chmod 644 ./crypted/authorised
chmod 644 ./crypted/app_update
echo 1 > ./crypted/authorised
echo 1 > ./crypted/app_update

echo "Copying firmware files into folder crypted..."
cp -r "$1"* ./crypted

umount ./crypted > /dev/null 2>&1
sync

echo "Done"

exit 0
