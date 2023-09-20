#!/bin/bash

## Call it as:
##    ./scripts/create_machine.sh machinename (jammy|lunar|bookworm)
##
## This script:
## copy the image taking one from `upstream-img/` folder (see get_upstream.sh)
## setup root password to 'root'
## setup network to 192.168.122.XX where XX is 31 or something stored into lastip.txt + 1
## store lastip.txt the last used XX
## create a machine based on the new image
##
## Note: this 192.168.122.0/24 network is my virbr0 that virt-install created the first time.
## This script is not usable from others, it is just for self explain and recall steps.
## When and if I create an explicit bridge creation step, then I fix this, maybe.

IMAGES="jammy lunar bookworm"

MACHINENAME=$1
IMAGE=$2

if test "$IMAGE" != "jammy" && test "$IMAGE" != "lunar" && test "$IMAGE" != "booklworm"; then
 echo "Image name must be in $IMAGES"
 echo "exiting..."
 exit 0
fi

echo -n -e "create machine\nName: $MACHINENAME\nImage: $IMAGE\nProceed? [y/N] "
read X

if test "$X" = "Y" || test "$X" = "y"; then
echo "proceeding...";
else
echo "giving up"
exit 0
fi

mkdir -p running_img

case "$IMAGE" in
        jammy)
        SRCFILENAME=jammy-server-cloudimg-amd64.img
        DSTIMGNAME=jammy-$MACHINENAME.img
        OSINFO=ubuntu22.04
        ;;
        lunar)
        SRCFILENAME=lunar-server-cloudimg-amd64.img
        DSTIMGNAME=lunar-$MACHINENAME.img
        OSINFO=ubuntu23.04
        ;;
        bookworm)
        SRCFILENAME=debian-12-genericcloud-amd64.qcow2
        DSTIMGNAME=debian-$MACHINENAME.img
        OSINFO=debian12
        ;;
esac

#echo -e "copying $SRCFILENAME into running_img/$DSTIMGNAME"

IMGPATH=`pwd`/running_img/$DSTIMGNAME
if [ -f $IMGPATH ]; then
        echo "$IMGPATH is in use, suffix int"
        MAX=20
        i=1
        AUGPATH=$IMGPATH.$i
        while [ $i -lt $MAX ] && [ -f $AUGPATH ]; do
        echo $AUGPATH" is in use, trying next"
                true $((i++))
                AUGPATH=$IMGPATH.$i
        done;
        if [ $i -eq $MAX ]; then
                echo "too many machine, dont you ...?"
                exit 2
        fi
        IMGPATH=$AUGPATH
else
echo "NOT EXISTS, its new"
fi
echo -e "copying $SRCFILENAME into $IMGPATH"
cp $SRCFILENAME $IMGPATH

sudo virt-customize -a $IMGPATH --root-password password:root
echo "root password setted to 'root'"

if [ -e "lastip.txt" ]; then
        IPL=`cat lastip.txt`
else
        IPL=30
fi
true $((IPL++))
echo $IPL>lastip.txt
IPADDR=192.168.122.$IPL

sed -E 's/IPIPIPIP/'"$IPADDR"'/' netplantmpl/0-network.yaml > network.yaml
MOUNTP=`pwd`/mnt
sudo guestmount -a $IMGPATH -m /dev/sda1 --pid-file guestmount.pid -o allow_other $MOUNTP
sudo cp network.yaml ./mnt/etc/netplan/0-network.yaml
sudo cp netplantmpl/first_setup.sh ./mnt/root/first_setup.sh
pid="$(cat guestmount.pid)"
sudo guestunmount $MOUNTP

timeout=30

count=$timeout

while kill -0 "$pid" 2>/dev/null && [ $count -gt 0 ]; do
    sleep 1
    ((count--))
done
sync

CMD="sudo virt-install --connect qemu:///system --import --name $MACHINENAME --osinfo $OSINFO --memory 2048 --network bridge=virbr0,model=virtio --graphics none --disk path=$IMGPATH,size=4 --noautoconsole"

# virt-install --osinfo list

echo $CMD
$CMD


## needed in the guest (as root):
#
# ./first_setup.sh
#
## it is in netplantmpl/first_setup.sh
## Then in the host:
#
# scripts/addauthorized_key.sh $MACHINAME