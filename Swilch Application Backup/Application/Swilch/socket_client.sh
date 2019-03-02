#!/bin/bash

exec 3<>/dev/tcp/127.0.1.1/8080

if [ $? -eq 0 ]; then
echo "Success"
else
echo "Failed"
exit 0
fi

echo -e "45" >&3
exec 3>&-


nc -l 8000 > /home/appusr_swilch/swilch/swilch_application_000.000.003/new.dat
echo "Wait"
CMD=$(cat /home/appusr_swilch/swilch/swilch_application_000.000.003/new.dat)
echo "CMD: $CMD"
if [ "$CMD" = "89" ]; then
	echo "$CMD Success"
else
	echo "$CMD Fail"
fi

#while true
#do
#echo "LoopST"
#read -r -u 3 -n 3  $MSG_IN <&3
#cat <&3
#echo "1"
#echo "$MSG_IN" > /home/avench/message
#if [ "$MSG_IN" -eq "AB" ]; then
#	touch /home/avench/success
#else
#	echo "NE"
#fi
#done

exit 0


