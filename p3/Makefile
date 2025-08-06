PORT_FORWARD_PID = .argocd_port_forward.pid
CLUSTER_NAME = iot-cluster
PORT_MAPPING = 8888:80@loadbalancer

SHELL := /bin/bash

# Namespace de démo
DEV_NS = dev
DEV_APP = hello-dev
DEV_FORWARD_PID = .dev_port_forward.pid
DEV_LOCAL_PORT = 8890
DEV_SVC_PORT = 80

.PHONY: all help create delete restart info install-argocd argo-port-forward argo-stop-forward argo-password create-argo-app forward-app-bg stop-forward-app

all: help

help:
	@echo "Available targets:"
	@echo "  make create				→ Créer le cluster K3D"
	@echo "  make delete				→ Supprimer le cluster K3D"
	@echo "  make restart				→ Recrée proprement le cluster"
	@echo "  make info				→ Affiche l'état du cluster"
	@echo "  make install-argocd			→ Installer ArgoCD"
	@echo "  make argo-port-forward		→ Démarrer le port-forward vers ArgoCD"
	@echo "  make argo-stop-forward		→ Arrêter le port-forward vers ArgoCD"
	@echo "  make argo-password			→ Afficher le mot de passe admin d'ArgoCD"
	@echo "  make create-argo-app			→ Créer l'application ArgoCD"
	@echo "  make forward-app-bg			→ Lancer le port-forward vers l'application en arrière-plan"
	@echo "  make stop-forward-app			→ Arrêter le port-forward de l'application"
	@echo "  make clean				→ Nettoyer les ressources et arrêter les services"

create:
	@echo "[INFO] Creating K3D cluster $(CLUSTER_NAME)..."
	k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 1 --port "$(PORT_MAPPING)" --wait


delete:
	@echo "[INFO] Deleting K3D cluster $(CLUSTER_NAME)..."
	k3d cluster delete $(CLUSTER_NAME)

restart: delete create

info:
	@echo "[INFO] Listing clusters and nodes..."
	k3d cluster list
	kubectl get nodes

install-argocd:
	chmod +x scripts/install-argocd.sh
	./scripts/install-argocd.sh


argo-port-forward:
	@echo "[INFO] Starting port-forward to ArgoCD on https://localhost:8080..."
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 & echo $$! > $(PORT_FORWARD_PID)
	@echo "[INFO] Port-forward started in background. PID saved to $(PORT_FORWARD_PID)."

argo-stop-forward:
	@if [ -f $(PORT_FORWARD_PID) ]; then \
		echo "[INFO] Stopping port-forward (PID=$$(cat $(PORT_FORWARD_PID)))..."; \
		kill $$(cat $(PORT_FORWARD_PID)) && rm -f $(PORT_FORWARD_PID); \
	else \
		echo "[WARN] No port-forward PID file found."; \
	fi

argo-password:
	@echo "[INFO] ArgoCD admin password:"
	@kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo

create-argo-app:
	kubectl apply -f ./confs/app.yaml

# Lance le port-forward en arrière-plan
forward-app-bg:
	nohup kubectl port-forward svc/playground -n dev 8889:8888 > /dev/null 2>&1 & echo $$! > .forward-app.pid
	@echo "Forwarding playground service on http://localhost:8889"

# Stoppe le port-forward
stop-forward-app:
	@if [ -f .forward-app.pid ]; then \
		kill $$(cat .forward-app.pid) && rm .forward-app.pid && echo "Stopped playground port-forward"; \
	else \
		echo "No running forward found"; \
	fi

clean: argo-stop-forward stop-forward-app
	@echo "[INFO] Cleaning up..."
	@rm -f $(PORT_FORWARD_PID) .forward-app.pid
	k3d cluster delete $(CLUSTER_NAME) || true
	@echo "[INFO] Cleanup complete."



## ----- DEV NAMESPACE (démo) -----

.PHONY: dev-up dev-status dev-port-forward dev-stop-forward dev-clean

dev-up:
	@echo "[INFO] Creating namespace '$(DEV_NS)' (if needed)..."
	@kubectl get ns $(DEV_NS) >/dev/null 2>&1 || kubectl create namespace $(DEV_NS)
	@echo "[INFO] Deploying a minimal app '$(DEV_APP)' in namespace '$(DEV_NS)'..."
	@kubectl apply -n $(DEV_NS) -f dev-yaml || true
	@echo "[INFO] Waiting for pods to be Ready..."
	@kubectl rollout status deployment/$(DEV_APP) -n $(DEV_NS) --timeout=120s
	@echo "[INFO] Done. Try: kubectl get all -n $(DEV_NS)"


dev-status:
	@echo "[INFO] Resources in namespace '$(DEV_NS)':"
	@kubectl get all -n $(DEV_NS)

dev-port-forward:
	@echo "[INFO] Port-forward $(DEV_APP) Service $(DEV_SVC_PORT) -> localhost:$(DEV_LOCAL_PORT)"
	@kubectl -n $(DEV_NS) port-forward svc/$(DEV_APP) $(DEV_LOCAL_PORT):$(DEV_SVC_PORT) > /dev/null 2>&1 & echo $$! > $(DEV_FORWARD_PID)
	@echo "[INFO] Open http://localhost:$(DEV_LOCAL_PORT)"

dev-stop-forward:
	@if [ -f $(DEV_FORWARD_PID) ]; then \
		if ps -p $$(cat $(DEV_FORWARD_PID)) > /dev/null 2>&1; then \
			echo "[INFO] Stopping dev port-forward (PID=$$(cat $(DEV_FORWARD_PID)))"; \
			kill $$(cat $(DEV_FORWARD_PID)); \
		else \
			echo "[WARN] No process found with PID=$$(cat $(DEV_FORWARD_PID)). Removing stale PID file."; \
		fi; \
		rm -f $(DEV_FORWARD_PID); \
	else \
		echo "[WARN] No dev port-forward PID file found."; \
	fi

dev-clean:
	@echo "[INFO] Deleting demo app from namespace '$(DEV_NS)'..."
	@kubectl delete svc/$(DEV_APP) -n $(DEV_NS) --ignore-not-found
	@kubectl delete deployment/$(DEV_APP) -n $(DEV_NS) --ignore-not-found
	@echo "[INFO] (Optional) To delete the namespace entirely, run: kubectl delete ns $(DEV_NS)"
