#!/bin/bash

IMAGEFILE=$1
MOUNTP=$2

CWD=`pwd`

IMAGEPATH=$PWD/$IMAGEFILE
MOUNTPATH=$PWD/$MOUNTP

if test -f $IMAGEPATH && test -d $MOUNTPATH; then
        echo "both exists"
        echo $IMAGEPATH
        echo $MOUNTPATH
fi
# exit 0


sudo guestmount -a $1 -m /dev/sda1 --pid-file guestmount.pid -o allow_other $2

