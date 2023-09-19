#!/bin/bash

## So far I need those packages in ubuntu

sudo apt install libvirt-clients virtinst bridge-utils cpu-checker libvirt-clients \
 libvirt-daemon qemu qemu-kvm libguestfs-tools ksmtuned

## ksmtuned is said to be usefull as kvm shared memory
## https://access.redhat.com/documentation/it-it/red_hat_enterprise_linux/6/html/virtualization_administration_guide/chap-ksm
