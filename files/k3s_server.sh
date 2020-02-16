#!/bin/bash -x

# Initialize an additional volume
if [ -e /dev/sda ]; then
  mkfs.ext4 /dev/sda
  echo '/dev/sda /data ext4 rw,noatime 0 2' >> /etc/fstab
  mkdir /data
  mount -a
fi

# Get public IP
public_ip=$(curl -s inet-ip.info)

export INSTALL_K3S_EXEC="--cluster-secret ${cluster_secret} --advertise-address $public_ip --node-external-ip $public_ip"

if [ `command -v curl` ]; then
  curl -sfL https://get.k3s.io | sh -s -
elif [ `command -v wget` ]; then
  wget -qO- https://get.k3s.io | sh -s -
fi
