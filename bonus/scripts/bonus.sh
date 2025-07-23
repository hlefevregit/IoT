#!/bin/bash

set -e

# Détecte l'IP de la VM GitLab (passée depuis Vagrantfile ou statique ici)
HOST_IP="192.168.42.99"
PROJECT_YAML="../confs/project.yaml"
APPLICATION_YAML="../confs/app.yaml"

echo "[INFO] IP de GitLab : $HOST_IP"
echo "[INFO] Namespace gitlab : création si nécessaire..."
kubectl get ns gitlab >/dev/null 2>&1 || kubectl create namespace gitlab

echo "[INFO] Déploiement du projet ArgoCD..."

if grep -q "HOST_IP" "$PROJECT_YAML"; then
  sed "s/HOST_IP/${HOST_IP}/g" "$PROJECT_YAML" | kubectl apply -n argocd -f -
else
  kubectl apply -n argocd -f "$PROJECT_YAML"
fi

sleep 2

echo "[INFO] Déploiement de l'application ArgoCD..."

if grep -q "HOST_IP" "$APPLICATION_YAML"; then
  sed "s/HOST_IP/${HOST_IP}/g" "$APPLICATION_YAML" | kubectl apply -n argocd -f -
else
  kubectl apply -n argocd -f "$APPLICATION_YAML"
fi

echo "[✅] BONUS terminé : Projet & Application GitLab enregistrés dans ArgoCD."
