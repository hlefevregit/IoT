#!/bin/bash

set -e

echo "[INFO] Creating namespaces..."
kubectl create namespace argocd || echo "[INFO] Namespace 'argocd' already exists"
kubectl create namespace dev || echo "[INFO] Namespace 'dev' already exists"

echo "[INFO] Installing Argo CD in 'argocd' namespace..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[INFO] Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s

echo "[INFO] Forwarding Argo CD UI on http://localhost:8080..."
echo "[INFO] Run this in a separate terminal to keep it alive:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"

echo "[INFO] Retrieving Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

echo "[DONE] Argo CD is installed and ready!"
