#!/bin/bash -x

# Get public IP
public_ip=$(curl -s inet-ip.info)

export INSTALL_K3S_EXEC="--cluster-secret ${cluster_secret} --advertise-address $public_ip --node-external-ip $public_ip"

if [ `command -v curl` ]; then
  curl -sfL https://get.k3s.io | sh -s -
elif [ `command -v wget` ]; then
  wget -qO- https://get.k3s.io | sh -s -
fi

