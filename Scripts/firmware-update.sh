#!/bin/bash

echo "Firmware update"
kernel_update=0
app_update=0
cont=0
missing=0

exec 3<>/dev/tcp/127.0.0.1/8080
if [ $? -eq 0 ]; then
	echo -e "44" >&3
	echo "USB hotplugged"
else
	sleep 1
	exec 3<>/dev/tcp/127.0.0.1/8080
	if [ $? -eq 0 ]; then
        	echo -e "44" >&3
        	echo "USB hotplugged"
	else
        	sleep 1
        	exec 3<>/dev/tcp/127.0.0.1/8080
        	if [ $? -eq 0 ]; then
                	echo -e "44" >&3
                	echo "USB hotplugged"
		else
        		sleep 1
        		exec 3<>/dev/tcp/127.0.0.1/8080
        		if [ $? -eq 0 ]; then
                		echo -e "44" >&3
                		echo "USB hotplugged"
			else
				echo "Failed to inform Monit"
                                exit 0
			fi
		fi
	fi
fi
exec 3>&-

sync
umount /dev/sda1 > /dev/null 2>&1
sleep 2
mount /dev/sda1 /mnt > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Usb device not found!!."
	echo FW_UPD_ERR_USB_MOUNT_ERROR > /etc/firmware-update-status
	exit 0
fi

if [ ! -d "/mnt/crypted" ]; then
	echo "Firmware directory not present"
	echo FW_UPD_ERR_FIRMWARE_DIRECTORY_NOT_FOUND > /etc/firmware-update-status
	sync
	umount /mnt > /dev/null 2>&1
	exit 0
fi

for file in /mnt/crypted/*
do
	if [[ "$(file -b $file)" != "data" && "$(file -b $file)" != "directory" ]]; then
                echo "Update directory contains unencrypted files"
		echo FW_UPD_ERR_UNENCRYPTED_FILES_FOUND > /etc/firmware-update-status
		sync
		umount /mnt > /dev/null 2>&1
        	exit 0
	elif [ "$(file -b $file)" == "directory" ]; then
		for i in $file/*
		do
			if [[ "$(file -b $i)" != "data" && "$(file -b $i)" != "directory" ]]; then
                		echo "Update directory contains unencrypted files"
                		echo FW_UPD_ERR_UNENCRYPTED_FILES_FOUND > /etc/firmware-update-status
				sync
				umount /mnt > /dev/null 2>&1
                		exit 0
			fi
		done
	fi
done

cat /bin/usb-pphrase | ecryptfs-add-passphrase --fnek > /dev/null 2>&1
mount -i -t ecryptfs /mnt/crypted/ /mnt/crypted/ -o ecryptfs_sig=faa2eb740f201c8d,ecryptfs_fnek_sig=5ac0db675b79d628,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs > /dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "Ecryptfs mount failed."
	echo FW_UPD_ERR_FIRMWARE_DECRYPT_FAILED > /etc/firmware-update-status
        sync
	umount /mnt > /dev/null 2>&1
        exit 0
fi

if [ -f "/mnt/crypted/authorised" ]; then
	if [ $(cat /mnt/crypted/authorised) -eq 0 ]; then
		echo "Authorisation failed"
		echo FW_UPD_ERR_AUTHENTICATION_FAILED > /etc/firmware-update-status
		sync
		umount /mnt/crypted > /dev/null 2>&1
        	umount /mnt > /dev/null 2>&1
		exit 0
	else
		echo "Authorised"
		echo 0 > /mnt/crypted/authorised
	fi
else
	echo FW_UPD_ERR_AUTHENTICATION_FAILED > /etc/firmware-update-status
	sync
	umount /mnt/crypted > /dev/null 2>&1
        umount /mnt > /dev/null 2>&1
	exit 0
fi

cur_kernel=$(ls /boot | grep vmlinuz)
cur_initrd=$(ls /boot | grep initrd)

new_kernel=$(ls /mnt/crypted | grep vmlinuz)
new_initrd=$(ls /mnt/crypted | grep initrd)

#cur_app=$(basename /home/appusr_swilch/swilch/swilch_app*)
#new_app=$(basename /mnt/crypted/swilch_app*)

cur_app=$(ls /home/appusr_swilch/swilch | grep swilch_application)
new_app=$(ls /mnt/crypted | grep swilch_application)

echo $cur_kernel
echo $cur_initrd
echo $new_kernel
echo $new_initrd
echo $cur_app
echo $new_app

if [ -f "/mnt/crypted/app_update" ]; then
        if [ $(cat /mnt/crypted/app_update) -eq 1 ]; then
                echo "App update enabled"

		if [ ! -z $new_app ]; then
			echo 0 > /mnt/crypted/app_update
			cur_app_v1=$(echo ${cur_app:19:3})
			cur_app_v2=$(echo ${cur_app:23:3})
			cur_app_v3=$(echo ${cur_app:27:3})

			new_app_v1=$(echo ${new_app:19:3})
			new_app_v2=$(echo ${new_app:23:3})
			new_app_v3=$(echo ${new_app:27:3})

			cur_app_version=$(echo ${cur_app:19:11})
			new_app_version=$(echo ${new_app:19:11})

			echo $cur_app_version
			echo $new_app_version
			echo $cur_app_v1
			echo $cur_app_v2
			echo $cur_app_v3
			echo $new_app_v1
			echo $new_app_v2
			echo $new_app_v3

			if [ $new_app_v1 -ge $cur_app_v1 ]; then
        			if [ $new_app_v1 -gt $cur_app_v1 ]; then
                			app_update=1
        			else
              				if [ $new_app_v2 -ge $cur_app_v2 ]; then
                        			if [ $new_app_v2 -gt $cur_app_v2 ]; then
                                			app_update=1
                        			else
                                			if [ $new_app_v3 -gt $cur_app_v3 ]; then
								app_update=1
                                			fi
						fi
					fi
                        	fi
                	fi
		else
			echo "Application update file not found"
			echo FW_UPD_ERR_FIRMWARE_FILE_MISSING > /etc/firmware-update-status
			app_update=0
		fi
	else
		echo "App update disabled"
	fi
else
	echo "Authorisation Failed"
fi

cur_kern_v1=$(echo ${cur_kernel:8:1})
cur_kern_v2=$(echo ${cur_kernel:10:1})
cur_kern_v3=$(echo ${cur_kernel:12:1})
cur_kern_v4=$(echo ${cur_kernel:14:2})

new_kern_v1=$(echo ${new_kernel:8:1})
new_kern_v2=$(echo ${new_kernel:10:1})
new_kern_v3=$(echo ${new_kernel:12:1})
new_kern_v4=$(echo ${new_kernel:14:2})

new_initrd_v1=$(echo ${new_initrd:11:1})
new_initrd_v2=$(echo ${new_initrd:13:1})
new_initrd_v3=$(echo ${new_initrd:15:1})
new_initrd_v4=$(echo ${new_initrd:17:2})

cur_kern_version=$(echo ${cur_kernel:8:8})
new_kern_version=$(echo ${new_kernel:8:8})

echo $cur_kern_version
echo $new_kern_version
echo $cur_kern_v1
echo $cur_kern_v2
echo $cur_kern_v3
echo $cur_kern_v4
echo $new_kern_v1
echo $new_kern_v2
echo $new_kern_v3
echo $new_kern_v4
echo $new_initrd_v1
echo $new_initrd_v2
echo $new_initrd_v3
echo $new_initrd_v4

if [[ $new_kern_v1 -ne $new_initrd_v1 || $new_kern_v2 -ne $new_initrd_v2 || $new_kern_v3 -ne $new_initrd_v3 || $new_kern_v4 -ne $new_initrd_v4 ]]; then
	echo "version mismatch in update files"
	echo FW_UPD_ERR_FIRMWARE_FILE_MISSING > /etc/firmware-update-status
	kernel_update=0
	missing=1
fi

if [[ -z $new_kernel || -z $new_initrd ]]; then
        echo "Missing kernel update files"
        echo FW_UPD_ERR_FIRMWARE_FILE_MISSING > /etc/firmware-update-status
	kernel_update=0
        missing=1
fi

if [ $missing -eq 0 ]; then
	if [ $new_kern_v1 -ge $cur_kern_v1 ]; then
        	if [ $new_kern_v1 -gt $cur_kern_v1 ]; then
                	kernel_update=1
        	else
              		if [ $new_kern_v2 -ge $cur_kern_v2 ]; then
                        	if [ $new_kern_v2 -gt $cur_kern_v2 ]; then
                                	kernel_update=1
                        	else
                                	if [ $new_kern_v3 -ge $cur_kern_v3 ]; then
                                        	if [ $new_kern_v3 -gt $cur_kern_v3 ]; then
                                                	kernel_update=1
                                        	else
                                                	if [ $new_kern_v4 -gt $cur_kern_v4 ]; then
                                                        	kernel_update=1
                                                	fi
                                        	fi
                                	fi
                        	fi
                	fi
        	fi
	fi
fi

echo "app_update=$app_update"
echo "kernel_update=$kernel_update"

if [[ $app_update -eq 0 && $kernel_update -eq 0 ]]; then
	echo "Firmware up to date"
	sync
	umount /mnt/crypted > /dev/null 2>&1
        umount /mnt > /dev/null 2>&1
        exit 0
fi

exec 3<>/dev/tcp/127.0.0.1/8080
if [ $? -eq 0 ]; then
	echo "Success"
	if [[ $app_update -eq 1 && $kernel_update -eq 1 ]]; then
		echo -e "47" >&3
		echo "Updating kernel & App"
	elif [ $app_update -eq 1 ]; then
		echo -e "46" >&3
		echo "Updating App only"
	elif [ $kernel_update -eq 1 ]; then
		echo -e "45" >&3
		echo "Updating Kernel & initrd only"
	else
		echo -e "12" >&3
		echo "Update not required"
		sync
		umount /mnt/crypted > /dev/null 2>&1
        	umount /mnt > /dev/null 2>&1
        	exec 3>&-
        	exit 0
	fi
	exec 3>&-
else
	sleep 1
	exec 3<>/dev/tcp/127.0.0.1/8080
	if [ $? -eq 0 ]; then
        	echo "Success"
        	if [[ $app_update -eq 1 && $kernel_update -eq 1 ]]; then
                	echo -e "47" >&3
                	echo "Updating kernel & App"
        	elif [ $app_update -eq 1 ]; then
                	echo -e "46" >&3
                	echo "Updating App only"
        	elif [ $kernel_update -eq 1 ]; then
                	echo -e "45" >&3
                	echo "Updating Kernel & initrd only"
        	else
                	echo -e "12" >&3
                	echo "Update not required"
                	sync
			umount /mnt/crypted > /dev/null 2>&1
                	umount /mnt > /dev/null 2>&1
                	exec 3>&-
                	exit 0
		fi
		exec 3>&-
	else
		sleep 1
		exec 3<>/dev/tcp/127.0.0.1/8080
		if [ $? -eq 0 ]; then
        		echo "Success"
        		if [[ $app_update -eq 1 && $kernel_update -eq 1 ]]; then
                		echo -e "47" >&3
                		echo "Updating kernel & App"
        		elif [ $app_update -eq 1 ]; then
                		echo -e "46" >&3
                		echo "Updating App only"
        		elif [ $kernel_update -eq 1 ]; then
                		echo -e "45" >&3
                		echo "Updating Kernel & initrd only"
        		else
                		echo -e "12" >&3
                		echo "Update not required"
                		sync
				umount /mnt/crypted > /dev/null 2>&1
                		umount /mnt > /dev/null 2>&1
                		exec 3>&-
                		exit 0
        		fi
        		exec 3>&-
		else
        		sleep 1
        		exec 3<>/dev/tcp/127.0.0.1/8080
        		if [ $? -eq 0 ]; then
                		echo "Success"
                		if [[ $app_update -eq 1 && $kernel_update -eq 1 ]]; then
                        		echo -e "47" >&3
                        		echo "Updating kernel & App"
                		elif [ $app_update -eq 1 ]; then
                        		echo -e "46" >&3
                        		echo "Updating App only"
                		elif [ $kernel_update -eq 1 ]; then
                        		echo -e "45" >&3
                        		echo "Updating Kernel & initrd only"
                		else
                                	echo -e "12" >&3
                                	echo "Update not required"
                                	sync
					umount /mnt/crypted > /dev/null 2>&1
                                	umount /mnt > /dev/null 2>&1
                                	exec 3>&-
                                	exit 0
                        	fi
				exec 3>&-
			else
				echo "Cannot inform monit"
				sync
				umount /mnt/crypted > /dev/null 2>&1
        			umount /mnt > /dev/null 2>&1
        			exit 0
			fi
		fi
	fi
fi

timeout 60 nc -l 8000 > /usr/local/recv_cmd.dat
CMD=$(cat /usr/local/recv_cmd.dat)
echo "CMD1: $CMD"
if [ "$CMD" -eq "90" ]; then
	cont=1
else
	echo "Update request rejected by app"
	echo FW_UPD_ERR_APP_BUSY > /etc/firmware-update-status
        sync
	umount /mnt/crypted > /dev/null 2>&1
        umount /mnt > /dev/null 2>&1
        exit 0
fi

if [[ $app_update -eq 1 && $cont -eq 1 ]]; then
        echo "Updating Application......."
        rm -rf /home/appusr_swilch/swilch/backup/* > /dev/null 2>&1
        cp -a /home/appusr_swilch/swilch/swilch_app* /home/appusr_swilch/swilch/bakup/ > /dev/null 2>&1
        rm -rf /home/appusr_swilch/swilch/swilch_app* > /dev/null 2>&1
        cp -a /mnt/crypted/$new_app /home/appusr_swilch/swilch/$new_app > /dev/null 2>&1
        chown -R appusr_swilch:appusr_swilch /home/appusr_swilch/swilch/$new_app
	chmod 775 /home/appusr_swilch/swilch/$new_app
	echo "App update done."
	if [ $kernel_update -eq 0 ]; then
		echo FW_UPD_SUCCESS > /etc/firmware-update-status
        	umount /mnt/crypted > /dev/null 2>&1
        	umount /mnt > /dev/null 2>&1
        	sync
        	reboot
	fi
else
        echo "App already up-to-date"
fi

if [[ $kernel_update -eq 1 && $cont -eq 1 ]]; then
        echo "Updating kernel and initrd...."
        rm /boot/vmlinuz* > /dev/null 2>&1
        rm /boot/initrd* > /dev/null 2>&1
        cp /mnt/crypted/$new_kernel /boot/$new_kernel
        cp /mnt/crypted/$new_initrd /boot/$new_initrd
	chmod 600 /boot/$new_kernel
	chmod 644 /boot/$new_initrd
        sed -i -e "130s/$cur_kern_version/$new_kern_version/g" -e "144s/$cur_kern_version/$new_kern_version/g" -e "145s/$cur_kern_version/$new_kern_version/g" -e "147s/$cur_kern_version/$new_kern_version/g" -e "149s/$cur_kern_version/$new_kern_version/g" -e "161s/$cur_kern_version/$new_kern_version/g" -e "162s/$cur_kern_version/$new_kern_version/g" -e "164s/$cur_kern_version/$new_kern_version/g" /boot/grub/grub.cfg
	sync
	umount /mnt/crypted > /dev/null 2>&1
	umount /mnt > /dev/null 2>&1
	touch /etc/update-status
	echo 1 > /etc/update-status
        echo "Done"
	echo FW_UPD_SUCCESS > /etc/firmware-update-status
        reboot
else
	sync
	echo "Kernel already up to date"
	umount /mnt/crypted > /dev/null 2>&1
	umount /mnt > /dev/null 2>&1
fi

exit 0
