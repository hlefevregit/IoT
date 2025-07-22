PORT_FORWARD_PID = .argocd_port_forward.pid
CLUSTER_NAME = iot-cluster
PORT_MAPPING = 8888:80@loadbalancer

.PHONY: all help create delete restart info install-argocd argo-port-forward argo-stop-forward argo-password create-argo-app forward-app-bg stop-forward-app

all: help

help:
	@echo "Available targets:"
	@echo "  make create   → Créer le cluster K3D"
	@echo "  make delete   → Supprimer le cluster K3D"
	@echo "  make restart  → Recrée proprement le cluster"
	@echo "  make info     → Affiche l'état du cluster"

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
