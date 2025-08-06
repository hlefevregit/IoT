#!/bin/bash

MASTER_IP="$1"

echo "[INFO] Waiting for node-token from controller..."
while [ ! -f /vagrant_shared/node-token ]; do
  echo "[INFO] node-token not found yet, sleeping 2s..."
  sleep 2
done

K3S_TOKEN=$(cat /vagrant_shared/node-token)

echo "[INFO] Installing K3s agent on $HOSTNAME..."
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN="$K3S_TOKEN" sh -
echo "[INFO] K3s agent installed on $HOSTNAME."
