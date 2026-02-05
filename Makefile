CLUSTER_NAME=k3d-cluster
IMAGE_NAME=custom-nginx:latest

.PHONY: all install-tools setup build import deploy clean

all: install-tools setup build import deploy

# 0. Installation des outils (Packer, Ansible, K3d + Lib Python)
install-tools:
	@echo "🔧 Vérification des outils..."
	@sudo rm -f /etc/apt/sources.list.d/yarn.list
	
	@# 1. K3d
	@which k3d >/dev/null || (echo "⬇️ Installation K3d..." && \
		curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash)
	
	@# 2. Packer (HashiCorp)
	@which packer >/dev/null || (echo "⬇️ Setup Packer..." && \
		sudo apt-get update && sudo apt-get install -y wget gpg && \
		wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
		sudo apt-get update && sudo apt-get install -y packer)
	
	@# 3. Ansible
	@which ansible >/dev/null || (echo "⬇️ Installation Ansible..." && \
		sudo apt-get install -y ansible)

	@# 4. Librairie Python Kubernetes (VIA APT - C'est ici la correction)
	@# On vérifie si le paquet est installé via dpkg, sinon on l'installe via apt
	@dpkg -s python3-kubernetes >/dev/null 2>&1 || (echo "⬇️ Installation Lib Python K8s..." && \
		sudo apt-get install -y python3-kubernetes)
	
	@echo "✅ Tous les outils sont prêts."

# 1. Création du cluster (Port 8081)
setup:
	@k3d cluster list $(CLUSTER_NAME) >/dev/null 2>&1 || \
	k3d cluster create $(CLUSTER_NAME) -p "8081:80@loadbalancer" --wait

# 2. Build packer
build:
	cd packer && packer init . && packer build nginx.pkr.hcl

# 3. Import dans k3d
import:
	k3d image import $(IMAGE_NAME) -c $(CLUSTER_NAME)

# 4. Déploiement Ansible
deploy:
	cd ansible && ansible-galaxy collection install kubernetes.core
	cd ansible && ansible-playbook -i inventory.ini playbooks/deploy.yml

clean:
	k3d cluster delete $(CLUSTER_NAME)