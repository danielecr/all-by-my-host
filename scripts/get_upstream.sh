#! /bin/sh

mkdir -p upstream-img
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -P upstream-img
wget https://cloud-images.ubuntu.com/lunar/current/lunar-server-cloudimg-amd64.img -P upstream-img
wget https://cloud-images.ubuntu.com/lunar/current/lunar-server-cloudimg-arm64.img -P upstream-img

https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2