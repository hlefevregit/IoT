#!/bin/bash

set -e

CLUSTER_NAME="bonus-cluster"

echo "[INFO] Vérification de Helm..."
if ! command -v helm &>/dev/null; then
  echo "[INFO] Installation de Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "[INFO] Helm est déjà installé."
fi

echo "[INFO] Vérification du cluster K3D..."
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo "[INFO] Création du cluster K3D '$CLUSTER_NAME'..."
  k3d cluster create "$CLUSTER_NAME" --servers 1 --agents 2 \
    --k3s-arg "--disable=traefik@server:0" \
    --port "8888:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --wait
else
  echo "[INFO] Le cluster '$CLUSTER_NAME' existe déjà."
fi

echo "[INFO] Vérification de l'accès au cluster..."
if ! kubectl cluster-info &>/dev/null; then
  echo "[ERREUR] Impossible d'accéder au cluster. Abandon."
  exit 1
fi

echo "[INFO] Création du namespace 'gitlab' (s'il n'existe pas)..."
kubectl get ns gitlab &>/dev/null || kubectl create namespace gitlab

echo "[INFO] Ajout du dépôt Helm GitLab..."
helm repo add gitlab https://charts.gitlab.io || true
helm repo update

echo "[INFO] Installation de GitLab via Helm..."
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=localhost \
  --set certmanager.install=false \
  --set nginx-ingress.enabled=true \
  --set nginx-ingress.controller.service.type=NodePort \
  --set certmanager-issuer.email=hugo.lefevre06@gmail.com \
  --values $(dirname $0)/../gitlab/gitlab-values.yaml \
  --timeout 10m
