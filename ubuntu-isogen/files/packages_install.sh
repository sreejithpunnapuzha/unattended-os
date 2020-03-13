#!/bin/bash

set -xe
echo "ubuntu-live" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu bionic-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse
deb http://archive.canonical.com/ubuntu bionic partner
EOF
apt-get update && apt-get install  -y --no-install-recommends \
   linux-generic \
   linux-image-generic \
   live-boot \
   systemd-sysv \
   apt-transport-https \
   openssh-server \
   curl \
   gnupg \
   iptables \
   cloud-init
echo 'root:r00tme' | chpasswd
apt-get clean all && rm -rf /var/lib/apt/lists/*
