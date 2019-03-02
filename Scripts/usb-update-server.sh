#!/bin/bash

echo "**USB Update server"

nc -l 8080 > /home/appusr_swilch/server.dat

cmd=$(cat /home/appusr_swilch/server.dat)
echo 0 > /home/appusr_swilch/server.dat

if [ "$cmd" -eq "44" ]; then
	echo "**cmd: $cmd"
	echo "**Success"
fi

nc -l 8080 > /home/appusr_swilch/server.dat

cmd=$(cat /home/appusr_swilch/server.dat)
echo 0 > /home/appusr_swilch/server.dat

if [[ "$cmd" -eq "45" || "$cmd" -eq "46" || "$cmd" -eq "47" || "$cmd" -eq "55" || "$cmd" -eq "56" || "$cmd" -eq "57" ]]; then
        echo "**cmd: $cmd"
        sleep 3
        exec 4<>/dev/tcp/127.0.0.1/8000
        if [ $? -eq 0 ]; then
                echo "**connected to port 8000"
                echo -e "90" >&4
                exec 4>&-
         else
                echo "**Error connecting to port 8000"
        fi
fi

exit 0
