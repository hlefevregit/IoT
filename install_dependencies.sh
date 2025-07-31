#!/bin/bash

set -e

echo "🛠  [1/6] Mise à jour des paquets..."
sudo apt-get update -y

echo "🐳 [2/6] Installation de Docker..."
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker $USER
else
  echo "✅ Docker déjà installé"
fi

echo "🔁 Redémarrage du service Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "📦 [3/6] Installation de K3D..."
if ! command -v k3d >/dev/null 2>&1; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  echo "✅ K3D déjà installé"
fi

echo "⚙️  [4/6] Installation de kubectl..."
if ! command -v kubectl >/dev/null 2>&1; then
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo "✅ kubectl déjà installé"
fi

echo "📦 [5/6] Installation de Helm..."
if ! command -v helm >/dev/null 2>&1; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "✅ Helm déjà installé"
fi

echo "🚀 [6/6] Installation de Argo CD CLI..."
if ! command -v argocd >/dev/null 2>&1; then
  VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  chmod +x argocd
  sudo mv argocd /usr/local/bin/argocd
else
  echo "✅ ArgoCD CLI déjà installé"
fi

echo ""
echo "🎉 Toutes les dépendances sont installées avec succès !"
echo "🔁 Déconnecte-toi/reconnecte-toi ou fais \`newgrp docker\` pour activer Docker sans sudo."
