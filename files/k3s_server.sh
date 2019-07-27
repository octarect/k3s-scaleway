#!/bin/bash -x

# [OSS]
export INSTALL_K3S_EXEC="--cluster-secret ${cluster_secret} --kubelet-arg='address=0.0.0.0'"

if [ `command -v curl` ]; then
  curl -sfL https://get.k3s.io | sh -s -
elif [ `command -v wget` ]; then
  wget -qO- https://get.k3s.io | sh -s -
fi

