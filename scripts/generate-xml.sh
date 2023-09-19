#!/bin/bash

MACHINENAME=nodonome1
IMGPATH=`pwd`/running_img/test.img
OSINFO=ubuntu23.04

virt-install --connect qemu:///system --import --name $MACHINENAME --osinfo $OSINFO --memory 2048 --network bridge=virbr0,model=virtio --graphics none --disk path=$IMGPATH,size=4 --print-xml


## then use `virsh define` feeding that xml