# Configuration
CLUSTER_NAME = dev-cluster
PORT_MAPPING = 8888:80@loadbalancer
GITLAB_PORT = 31080
ARGOCD_PORT = 8081
PORT_FORWARD_PID = .argocd_port_forward.pid
GITLAB_HOST = http://172.18.0.5
ARGOCD_NS = argocd
APP_NS = my-app
APP_NAME = my-k8s-app

# GitLab repo (remplacer les valeurs si besoin)
GIT_REPO_URL = $(GITLAB_HOST)/hulefevr-group/iot-hulefevr.git
GIT_USER = root 
GIT_PASS ?= monNouveauMotDePasse # Recommandé : injecter depuis ENV

.PHONY: all help create delete restart info \
        gitlab-up \
        install-argocd argo-port-forward argo-stop-forward argo-password \
        argocd-login argocd-repo-add app-create app-sync \
        forward-app-bg stop-forward-app clean check-tools

all: check-tools create gitlab-up install-argocd argo-port-forward argocd-login argocd-repo-add app-create app-sync forward-app-bg

help:
	@echo "Available targets:"
	@echo "  make create           → Créer le cluster K3D"
	@echo "  make delete           → Supprimer le cluster K3D"
	@echo "  make restart          → Recrée proprement le cluster"
	@echo "  make gitlab-up        → Démarre GitLab local via docker-compose"
	@echo "  make install-argocd   → Installe Argo CD"
	@echo "  make argo-port-forward→ Forward ArgoCD vers localhost:8081"
	@echo "  make argo-password    → Affiche le mot de passe admin ArgoCD"
	@echo "  make argocd-login     → Se connecte à ArgoCD via CLI"
	@echo "  make argocd-repo-add  → Ajoute le repo GitLab à ArgoCD"
	@echo "  make app-create       → Crée l'app ArgoCD"
	@echo "  make app-sync         → Synchronise l'app"
	@echo "  make clean            → Supprime tout proprement"

check-tools:
	@command -v helm >/dev/null 2>&1 || { echo >&2 "Helm is not installed. Aborting."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is not installed. Aborting."; exit 1; }
	@command -v k3d >/dev/null 2>&1 || { echo >&2 "k3d is not installed. Aborting."; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed. Aborting."; exit 1; }

create:
	@echo "[INFO] Creating K3D cluster $(CLUSTER_NAME)..."
	k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 1 --port "$(PORT_MAPPING)" --port $(GITLAB_PORT):31080@loadbalancer || true

delete:
	@echo "[INFO] Deleting K3D cluster $(CLUSTER_NAME)..."
	k3d cluster delete $(CLUSTER_NAME)

restart: delete create

info:
	k3d cluster list
	kubectl get nodes

gitlab-up:
	@echo "[INFO] Starting GitLab container (port $(GITLAB_PORT))..."
	docker-compose up -d

install-argocd:
	kubectl create namespace $(ARGOCD_NS) || true
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	helm install argocd argo/argo-cd --namespace $(ARGOCD_NS) || true

argo-port-forward:
	@echo "[INFO] Forwarding ArgoCD to localhost:$(ARGOCD_PORT)..."
	@kubectl port-forward svc/argocd-server -n $(ARGOCD_NS) $(ARGOCD_PORT):443 > /dev/null 2>&1 & echo $$! > $(PORT_FORWARD_PID)
	@echo "[INFO] ArgoCD forwarded on https://localhost:$(ARGOCD_PORT)"


argo-stop-forward:
	@if [ -f $(PORT_FORWARD_PID) ]; then \
		if ps -p $$(cat $(PORT_FORWARD_PID)) > /dev/null 2>&1; then \
			kill $$(cat $(PORT_FORWARD_PID)) && echo "[INFO] Stopped ArgoCD port-forward"; \
		else \
			echo "[WARN] No process found with PID=$$(cat $(PORT_FORWARD_PID)). Removing stale PID file."; \
		fi; \
		rm -f $(PORT_FORWARD_PID); \
	else \
		echo "[WARN] No port-forward PID file found."; \
	fi

argo-password:
	@echo "[INFO] ArgoCD admin password:"
	@kubectl get secret argocd-initial-admin-secret -n $(ARGOCD_NS) -o jsonpath="{.data.password}" | base64 -d && echo

argocd-login:
	@echo "[INFO] Logging into ArgoCD..."
	$(eval ARGO_PWD := $(shell kubectl get secret argocd-initial-admin-secret -n $(ARGOCD_NS) -o jsonpath="{.data.password}" | base64 -d))
	argocd login localhost:$(ARGOCD_PORT) --username admin --password $(ARGO_PWD) --insecure


argocd-repo-add:
	@echo "[INFO] Adding GitLab repo to ArgoCD..."
	@bash -c "argocd repo add $(GIT_REPO_URL) --username $(GIT_USER) --password $(GIT_PASS) || true"


app-create:
	@echo "[INFO] Creating ArgoCD application..."
	kubectl create namespace $(APP_NS) || true
	argocd app create $(APP_NAME) \
		--repo $(GIT_REPO_URL) \
		--path . \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace $(APP_NS) || true

app-sync:
	@echo "[INFO] Syncing ArgoCD application..."
	argocd app sync $(APP_NAME)

forward-app-bg:
	nohup kubectl port-forward svc/playground -n $(APP_NS) 8889:8888 > /dev/null 2>&1 & echo $$! > .forward-app.pid
	@echo "[INFO] Forwarding playground service on http://localhost:8889"


stop-forward-app:
	@if [ -f .forward-app.pid ]; then \
		if ps -p $$(cat .forward-app.pid) > /dev/null 2>&1; then \
			kill $$(cat .forward-app.pid) && rm .forward-app.pid && echo "[INFO] Stopped playground port-forward"; \
		else \
			echo "[WARN] No process found with PID=$$(cat .forward-app.pid). Removing stale PID file."; \
			rm .forward-app.pid; \
		fi \
	else \
		echo "[WARN] No running forward found"; \
	fi




clean: argo-stop-forward stop-forward-app
	@echo "[INFO] Cleaning up..."
	docker-compose down
	helm uninstall argocd -n $(ARGOCD_NS) || true
	kubectl delete namespace $(ARGOCD_NS) || true
	kubectl delete namespace $(APP_NS) || true
	k3d cluster delete $(CLUSTER_NAME)
	@rm -f $(PORT_FORWARD_PID) .forward-app.pid
	@echo "[INFO] Cleanup complete."