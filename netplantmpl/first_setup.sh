#!/bin/sh
username=ubuntu
password=ubuntu

adduser --gecos "" --disabled-password $username
chpasswd <<<"$username:$password"

apt update; apt -y full-upgrade; apt install -y qemu-guest-agent
