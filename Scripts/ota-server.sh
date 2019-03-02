#!/bin/bash

scp -r -o StrictHostKeyChecking=no "$1" appusr_swilch@10.42.0.10:/firmware
#ssh -o StrictHostKeyChecking=no appusr_swilch@192.168.2.53 '/usr/local/bin/ota-update.sh'

ssh -o StrictHostKeyChecking=no -t appusr_swilch@10.42.0.10 "sudo keyctl link @u @s; sudo /usr/local/bin/ota-update.sh"

scp -r -o StrictHostKeyChecking=no appusr_swilch@10.42.0.10:/etc/firmware-update-status ./firmware-update-status

upd_sts=$(cat ./firmware-update-status)
echo "$upd_sts"

if [ "$upd_sts" == "FW_UPD_SUCCESS" ]; then
	ssh -o StrictHostKeyChecking=no -t appusr_swilch@10.42.0.10 "sudo reboot"
fi

#ssh -t appusr_swilch@192.168.2.53 << EOSSH
#sudo /usr/local/bin/ota-update.sh
#EOSSH

exit 0
