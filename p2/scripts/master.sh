#!/bin/bash

echo "[INFO] Installing K3s server..."
curl -sfL https://get.k3s.io | sh -

sudo chmod 644 /etc/rancher/k3s/k3s.yaml


echo "[INFO] K3s installed. Verifying node:"
kubectl get node
