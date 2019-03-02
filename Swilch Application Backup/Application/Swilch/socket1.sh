#!/bin/bash

echo 5

exec 3<>/dev/tcp/localhost/9999
echo -e -n "AB" >&3
read -r -u -n $MSG_IN <&3
echo $MSG_IN

exit 0
