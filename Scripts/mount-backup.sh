#!/bin/bash

cat /bin/mount-pphrase | sudo ecryptfs-add-passphrase --fnek > /dev/null 2>&1

mount -i -t ecryptfs /backup/.ecryptfs/recusr_swilch/.Private /backup/recusr_swilch -o ecryptfs_sig=d20f903d177118df,ecryptfs_fnek_sig=dbcaf97f225926f6,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1

#ecryptfs_sig=d20f903d177118df
#ecryptfs_fnek_sig=dbcaf97f225926f6

#Passphrase=7ab5bc381c29443802126f02ec4c25d6
