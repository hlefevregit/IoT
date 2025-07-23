.PHONY: all apply delete restart up down clean h
 
h:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  up:        Start Vagrant machine"
	@echo "  down:      Destroy Vagrant machine"
	@echo "  apply:     Apply all YAML configs"
	@echo "  delete:    Delete all Kubernetes resources"
	@echo "  restart:   Delete + re-apply all"
	@echo "  clean:     Destroy VMs + cleanup"
	@echo "  h:         Show this help message"

up:
	@echo "Starting Vagrant machine..." 
	vagrant up

down:
	@echo "Destroying Vagrant machine..."
	vagrant destroy -f

apply:
	@echo "Applying all Kubernetes config..."
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app1/app1-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app2/app2-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/app3/app3-deploy.yaml'
	vagrant ssh hulefevrS -c 'k3s kubectl apply -f /vagrant/config/ingress.yaml'

delete:
	@echo "Deleting all Kubernetes config..."
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app1/app1-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app2/app2-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/app3/app3-deploy.yaml --ignore-not-found'
	vagrant ssh hulefevrS -c 'k3s kubectl delete -f /vagrant/config/ingress.yaml --ignore-not-found'

restart: delete apply

clean: delete
	@echo "Cleaning everything..."
	vagrant destroy -f
	rm -rf .vagrant

