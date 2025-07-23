# CLUSTER_NAME=bonus-cluster
# NAMESPACE=gitlab
# GITLAB_SVC=gitlab-webservice-default

# .PHONY: all setup port-forward show-password clean clean-gitlab-pods check-pods reinstall-gitlab help

# all: setup

# setup:
# 	@echo "[INFO] Lancement du setup..."
# 	bash scripts/setup.sh

# port-forward:
# 	@echo "[INFO] Port-forwarding GitLab depuis le cluster..."
# 	kubectl port-forward -n $(NAMESPACE) svc/$(GITLAB_SVC) 8080:8080

# show-password:
# 	@echo "[INFO] Récupération du mot de passe root GitLab..."
# 	kubectl get secret -n $(NAMESPACE) gitlab-gitlab-initial-root-password -ojsonpath="{.data.password}" | base64 --decode; echo

# clean:
# 	@echo "[INFO] Suppression du cluster K3D..."
# 	k3d cluster delete $(CLUSTER_NAME)

# clean-gitlab-pods:
# 	@echo "[INFO] Suppression des pods Evicted ou en erreur dans le namespace gitlab..."
# 	@kubectl get pods -n gitlab --no-headers | awk '/Evicted|Error|CrashLoopBackOff/ {print $$1}' | xargs -r kubectl delete pod -n gitlab
# 	@echo "[INFO] Nettoyage terminé."

# check-pods:
# 	@echo "[INFO] Vérification des pods dans le namespace '$(NAMESPACE)'..."
# 	@kubectl get pods -n $(NAMESPACE)
# 	@if kubectl get pods -n $(NAMESPACE) --no-headers | grep -vE 'Running|Completed' > /dev/null; then \
# 		echo "[ERREUR] Certains pods ne sont pas encore prêts."; \
# 		exit 1; \
# 	else \
# 		echo "[OK] Tous les pods sont prêts."; \
# 	fi

# reinstall-gitlab:
# 	@echo "[INFO] Réinstallation de GitLab..."
# 	-helm uninstall gitlab -n $(NAMESPACE)
# 	-kubectl delete ns $(NAMESPACE) --wait
# 	kubectl create ns $(NAMESPACE)
# 	helm install gitlab gitlab/gitlab -n $(NAMESPACE) -f ./gitlab/gitlab-values.yaml

# help:
# 	@echo "Commandes disponibles :"
# 	@echo "  make setup               - Lancer le setup complet"
# 	@echo "  make port-forward        - Faire un port-forward sur http://localhost:8080"
# 	@echo "  make show-password       - Afficher le mot de passe root initial"
# 	@echo "  make clean               - Supprimer le cluster K3D"
# 	@echo "  make clean-gitlab-pods   - Supprimer les pods GitLab en erreur/Evicted"
# 	@echo "  make check-pods          - Vérifier si tous les pods GitLab sont prêts"
# 	@echo "  make reinstall-gitlab    - Supprimer et réinstaller GitLab uniquement"
# 	@echo "  make help                - Afficher cette aide"


.PHONY: all up vm-up k3d-up install-argocd setup-gitlab bonus destroy clean help

# Config
VM_NAME=glab
GITLAB_IP=192.168.42.99
CLUSTER_NAME=bonus-cluster

## ===== COMMANDES =====

all: up install-argocd setup-gitlab bonus

up: vm-up k3d-up ## Provisionne la VM GitLab + le cluster K3D

vm-up: ## Lance la VM GitLab via Vagrant
	@echo "[INFO] Démarrage de la VM GitLab..."
	vagrant up

k3d-up: ## Crée le cluster K3D
	@echo "[INFO] Création du cluster K3D..."
	k3d cluster create $(CLUSTER_NAME) --agents 2 --port "8888:80@loadbalancer" --port "8443:443@loadbalancer" --wait

install-argocd: ## Installe ArgoCD dans K3D
	@echo "[INFO] Installation de ArgoCD..."
	kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "[OK] ArgoCD installé."

setup-gitlab: ## Affiche infos de config GitLab (VM)
	@echo "[INFO] VM GitLab dispo sur : http://$(GITLAB_IP):9999"
	@echo "[INFO] Mot de passe root :"
	vagrant ssh $(VM_NAME) -c "sudo cat /etc/gitlab/initial_root_password || echo 'Non dispo.'"

bonus: ## Déploie projet & app dans ArgoCD
	@echo "[INFO] Déploiement bonus avec scripts/bonus.sh..."
	HOST_IP=$(GITLAB_IP) bash scripts/bonus.sh

destroy: ## Supprime VM + cluster
	@echo "[INFO] Suppression de la VM et du cluster..."
	vagrant destroy -f
	k3d cluster delete $(CLUSTER_NAME)

clean: ## Supprime le cluster uniquement
	@echo "[INFO] Suppression du cluster K3D uniquement..."
	k3d cluster delete $(CLUSTER_NAME)

help: ## Affiche ce message d'aide
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
