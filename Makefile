CLUSTER_NAME=k3d-cluster
IMAGE_NAME=custom-nginx:latest
# Port par défaut (si libre)
HOST_PORT?=8081

.PHONY: all install-tools setup build import deploy clean

all: install-tools setup build import deploy

# 0. Installation des outils (Ajout de lsof pour scanner les ports)
install-tools:
	@echo "🔧 Vérification des outils..."
	@sudo rm -f /etc/apt/sources.list.d/yarn.list
	
	@# Installation de lsof (Nécessaire pour vérifier les ports)
	@which lsof >/dev/null || (echo "⬇️ Installation lsof..." && sudo apt-get update && sudo apt-get install -y lsof)

	@# Installation K3d
	@which k3d >/dev/null || (echo "⬇️ Installation K3d..." && curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash)
	
	@# Installation Packer
	@which packer >/dev/null || (echo "⬇️ Setup Packer..." && \
		sudo apt-get update && sudo apt-get install -y wget gpg && \
		wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
		sudo apt-get update && sudo apt-get install -y packer)
	
	@# Installation Ansible
	@which ansible >/dev/null || (echo "⬇️ Installation Ansible..." && sudo apt-get install -y ansible)

	@# Lib Python Kubernetes
	@dpkg -s python3-kubernetes >/dev/null 2>&1 || (echo "⬇️ Installation Lib Python K8s..." && sudo apt-get install -y python3-kubernetes)
	
	@echo "✅ Outils prêts."

# 1. Création du cluster (AVEC DÉTECTION DE PORT INTERACTIVE)
setup:
	@# On vérifie d'abord si le cluster existe déjà pour ne pas tout casser
	@if k3d cluster list $(CLUSTER_NAME) >/dev/null 2>&1; then \
		echo "✅ Le cluster $(CLUSTER_NAME) existe déjà. On continue."; \
	else \
		echo "🔍 Vérification du port $(HOST_PORT)..."; \
		port=$(HOST_PORT); \
		# Boucle : Tant que 'lsof' trouve quelque chose sur ce port, on demande un nouveau port \
		while sudo lsof -i :$$port >/dev/null 2>&1; do \
			echo "⚠️  Aie ! Le port $$port est déjà utilisé."; \
			read -p "👉 Entrez un nouveau port libre (ex: 8083) : " new_port; \
			port=$$new_port; \
		done; \
		echo "🚀 Port $$port validé ! Création du cluster..."; \
		k3d cluster create $(CLUSTER_NAME) -p "$$port:80@loadbalancer" --wait; \
	fi

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