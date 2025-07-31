# === CONFIGURATION GÉNÉRALE ===
VAGRANT_CMD = vagrant
PROVIDER = libvirt
CLUSTER_NAME = iot-cluster
PORT_MAPPING = 8888:80@loadbalancer
PORT_FORWARD_PID = .argocd_port_forward.pid

# === AIDE ===
.PHONY: help
help:
	@echo "🔧 Commandes Make disponibles :"
	@echo ""
	@echo "  ### P1 – VM de base ###"
	@echo "  make p1-up              → Démarre les VMs"
	@echo "  make p1-halt            → Arrête les VMs"
	@echo "  make p1-reload          → Redémarre les VMs"
	@echo "  make p1-destroy         → Détruit les VMs"
	@echo "  make p1-ssh-server      → SSH dans la VM serveur"
	@echo "  make p1-ssh-worker      → SSH dans la VM worker"
	@echo "  make p1-prune           → Nettoie complètement P1"
	@echo ""
	@echo "  ### P2 – Déploiement K8s ###"
	@echo "  make p2-up              → Démarre la VM"
	@echo "  make p2-down            → Détruit la VM"
	@echo "  make p2-apply           → Applique les manifests"
	@echo "  make p2-delete          → Supprime les ressources"
	@echo "  make p2-restart         → Supprime et réapplique"
	@echo "  make p2-clean           → Supprime tout"
	@echo ""
	@echo "  ### P3 – K3D + ArgoCD ###"
	@echo "  make p3-create          → Crée le cluster K3D"
	@echo "  make p3-delete          → Supprime le cluster"
	@echo "  make p3-restart         → Reset du cluster"
	@echo "  make p3-info            → Infos sur le cluster"
	@echo "  make p3-install-argocd  → Installe ArgoCD"
	@echo "  make p3-port-forward    → Port-forward vers ArgoCD"
	@echo "  make p3-stop-forward    → Stop port-forward"
	@echo "  make p3-password        → Affiche le mot de passe admin Argo"
	@echo "  make p3-create-app      → Applique le fichier app.yaml"
	@echo "  make p3-forward-app     → Port-forward playground"
	@echo "  make p3-stop-app        → Stop port-forward playground"
	@echo "  make p3-clean           → Clean Argo + forward"

# === P1 ===
.PHONY: p1-up p1-halt p1-reload p1-destroy p1-ssh-server p1-ssh-worker p1-prune

p1-up:
	sudo $(VAGRANT_CMD) up --provider=$(PROVIDER)

p1-halt:
	$(VAGRANT_CMD) halt

p1-reload:
	$(VAGRANT_CMD) reload

p1-destroy:
	$(VAGRANT_CMD) destroy -f

p1-ssh-server:
	sudo chown -R $(USER):$(USER) .
	$(VAGRANT_CMD) ssh mutezaS

p1-ssh-worker:
	sudo chown -R $(USER):$(USER) .
	$(VAGRANT_CMD) ssh hulefevrSW

p1-prune:
	$(VAGRANT_CMD) halt
	sudo virsh undefine p1_mutezaS --remove-all-storage || true
	sudo virsh undefine p1_hulefevrSW --remove-all-storage || true
	rm -rf .vagrant

# === P2 ===
.PHONY: p2-up p2-down p2-apply p2-delete p2-restart p2-clean

p2-up:
	vagrant up

p2-down:
	vagrant destroy -f

p2-apply:
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app1/app1-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app2/app2-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app3/app3-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/ingress.yaml'

p2-delete:
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app1/app1-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app2/app2-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app3/app3-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/ingress.yaml --ignore-not-found'

p2-restart: p2-delete p2-apply

p2-clean: p2-delete
	rm -rf .vagrant

# === P3 ===
.PHONY: p3-create p3-delete p3-restart p3-info p3-install-argocd p3-port-forward p3-stop-forward p3-password p3-create-app p3-forward-app p3-stop-app p3-clean

p3-create:
	k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 1 --port "$(PORT_MAPPING)" --wait

p3-delete:
	k3d cluster delete $(CLUSTER_NAME)

p3-restart: p3-delete p3-create

p3-info:
	k3d cluster list
	kubectl get nodes

p3-install-argocd:
	chmod +x scripts/install-argocd.sh
	./scripts/install-argocd.sh

p3-port-forward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 & echo $$! > $(PORT_FORWARD_PID)

p3-stop-forward:
	@if [ -f $(PORT_FORWARD_PID) ]; then \
		kill $$(cat $(PORT_FORWARD_PID)) && rm -f $(PORT_FORWARD_PID); \
	else \
		echo "[WARN] No port-forward PID found."; \
	fi

p3-password:
	kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo

p3-create-app:
	kubectl apply -f ./confs/app.yaml

p3-forward-app:
	nohup kubectl port-forward svc/playground -n dev 8889:8888 > /dev/null 2>&1 & echo $$! > .forward-app.pid

p3-stop-app:
	@if [ -f .forward-app.pid ]; then \
		kill $$(cat .forward-app.pid) && rm .forward-app.pid; \
	else \
		echo "No running forward found."; \
	fi

p3-clean: p3-stop-forward p3-stop-app
	rm -f $(PORT_FORWARD_PID) .forward-app.pid
