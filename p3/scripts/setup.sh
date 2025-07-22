#!/bin/bash

set -e

echo "[+] Updating and upgrading the system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[+] Installing necessary packages..."

sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release git

echo "[+] Installing Docker..."

# Remove old Docker if any
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
# Install Docker dependencies
sudo apt-get install -y docker.io
# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "[+] Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[+] Installing k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "[+] Installing ArgoCD CLI..."

curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/argocd


echo "[✓] All tools installed!"
echo "→ You may need to logout/login or run: newgrp docker"