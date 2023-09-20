#!/bin/sh
username=ubuntu
password=ubuntu

adduser --gecos "" --disabled-password $username
chpasswd <<EOL
$username:$password
EOL

usermod -aG sudo $username

apt update; apt -y full-upgrade; apt install -y qemu-guest-agent
