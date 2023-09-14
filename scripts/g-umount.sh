#!/bin/bash

MOUNTP=$1

CWD=`pwd`

MOUNTPATH=$PWD/$MOUNTP

pid="$(cat guestmount.pid)"
sudo guestunmount $MOUNTPATH

timeout=10

count=$timeout

while kill -0 "$pid" 2>/dev/null && [ $count -gt 0 ]; do
    sleep 1
    ((count--))
done

if [ $count -eq 0 ]; then
    echo "$0: wait for guestmount to exit failed after $timeout seconds"
    exit 1
fi
