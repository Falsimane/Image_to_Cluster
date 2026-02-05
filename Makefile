CLUSTER_NAME=k3d-cluster 
IMAGE_NAME=custom-nginx:latest

.PHONY all setup build import deploy clean 

all: setup build import deploy 

#1. Création du cluster, si pas déjà fait 
setup:
	k3d cluster create $(CLUSTER_NAME) --ports "8080:80@loadbalancer" --wait || echo "Cluster existing..."

#2. Build packer
build: 
	cd packer && packer init . && packer build nginx.pkr.hcl

#3 Import dans k3d 
import: 
	k3d image import $(IMAGE_NAME) -c $(CLUSTER_NAME)

#4. Déploiement Ansible
deploy:
	cd ansible && ansible-galaxy collection install kubernetes.core
	cd ansible && ansible-playbook -i inventory.ini playbooks/deploy.yml

clean:
	k3d cluster delete $(CLUSTER_NAME