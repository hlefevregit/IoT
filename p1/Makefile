# Configuration
VAGRANT_CMD = vagrant
PROVIDER = libvirt

## Démarrer les VMs
up:
	sudo $(VAGRANT_CMD) up --provider=$(PROVIDER)

## Arrêter les VMs
halt:
	$(VAGRANT_CMD) halt

## Redémarrer les VMs
reload:
	$(VAGRANT_CMD) reload

## Détruire les VMs
destroy:
	$(VAGRANT_CMD) destroy -f

## Accès SSH au serveur
ssh-server:
	$(VAGRANT_CMD) ssh mutezaS

##

p1-prune:
# Nettoyer les VMs et les ressources associées
	$(VAGRANT_CMD) halt
	# sudo virsh destroy p1_mutezaS          
	# sudo virsh destroy p1_hulefevrSW
	sudo virsh undefine p1_mutezaS --remove-all-storage
	sudo virsh undefine p1_hulefevrSW --remove-all-storage
	rm -rf .vagrant
