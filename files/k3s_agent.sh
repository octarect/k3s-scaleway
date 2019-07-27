#!/bin/bash -x

export INSTALL_K3S_EXEC="agent --server ${server_url} --cluster-secret ${cluster_secret}"

if [ `command -v curl` ]; then
  curl -sfL https://get.k3s.io | sh -s -
elif [ `command -v wget` ]; then
  wget -qO- https://get.k3s.io | sh -s -
fi

