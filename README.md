------------------------------------------------------------------------------------------------------
ATELIER FROM IMAGE TO CLUSTER
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : Cet atelier consiste à **industrialiser le cycle de vie d’une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l’aide d’**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.
L’objectif est de comprendre comment des outils d’Infrastructure as Code permettent de passer d’un artefact applicatif maîtrisé à un déploiement cohérent et automatisé sur une plateforme d’exécution.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
**Faites un Fork de ce projet**. Si besion, voici une vidéo d'accompagnement pour vous aider dans les "Forks" : [Forker ce projet](https://youtu.be/p33-7XQ29zQ) 
  
Ensuite depuis l'onglet [CODE] de votre nouveau Repository, **ouvrez un Codespace Github**.
  
---------------------------------------------------
Séquence 2 : Création du cluster Kubernetes K3d
---------------------------------------------------
Objectif : Créer votre cluster Kubernetes K3d  
Difficulté : Simple (~5 minutes)
---------------------------------------------------
Vous allez dans cette séquence mettre en place un cluster Kubernetes K3d contenant un master et 2 workers.  
Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Création du cluster K3d**  
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
```
k3d cluster create lab \
  --servers 1 \
  --agents 2
```
**vérification du cluster**  
```
kubectl get nodes
```
**Déploiement d'une application (Docker Mario)**  
```
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl get svc
```
**Forward du port 80**  
```
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```
**Réccupération de l'URL de l'application Mario** 
Votre application Mario est déployée sur le cluster K3d. Pour obtenir votre URL cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **8080** (Visibilité du port).
Ouvrez l'URL dans votre navigateur et jouer !

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Customisez un image Docker avec Packer et déploiement sur K3d via Ansible
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Créez une **image applicative customisée à l'aide de Packer** (Image de base Nginx embarquant le fichier index.html présent à la racine de ce Repository), puis déployer cette image customisée sur votre **cluster K3d** via **Ansible**, le tout toujours dans **GitHub Codespace**.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](Architecture_cible.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation du cluster Kubernetes K3d (Séquence 1)
2. Installation de Packer et Ansible
3. Build de l'image customisée (Nginx + index.html)
4. Import de l'image dans K3d
5. Déploiement du service dans K3d via Ansible
6. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------

Voici comment utiliser et comprendre la solution déployée dans ce dépôt.

### 0. Prérequis

Assurez-vous bien d'être dans un environnement GitHub Codespace (cf. Séquence 1). Le projet utilise des scripts conçus pour cet environnement Linux.

### 1. Démarrage rapide

La complexité du lancement a été abstraite derrière un Makefile. Pour lancer le déploiement complet, il faut se trouver à la racine du répertoire. Ensuite, il suffit d'exécuter : 

`make all`

Ce que fait cette commande automatiquement :
1. Vérification des outils : Installe Packer, Ansible et les librairies nécessaires si elles sont absentes.
2. Gestion intelligente du port : Vérifie si le port par défaut (8081) est libre. S'il est occupé, un prompt interactif vous demandera d'en choisir un nouveau.
3. Setup K3d : Crée le cluster Kubernetes.
4. Build Packer : Construit l'image custom-nginx:latest avec votre HTML.
5. Import : Injecte l'image directement dans les nœuds du cluster.
6. Déploiement : Lance le playbook Ansible pour créer les ressources Kubernetes (Ingress, Service, Deployment).

### 2. Accès à l'application

Une fois le déploiement terminé (message PLAY RECAP ... failed=0), votre application est accessible :
1. Ouvrez l'onglet [PORTS] dans VS Code (en bas de l'écran).
2. Repérez le port 8081 (ou celui que vous avez défini).
3. Cliquez sur l'icône "Globe" 🌐 (Open in Browser).
4. Vous devriez voir la page web personnalisée s'afficher (changer le fichier index.html).

### 3. Gestion des ports

Gestion des conflits de ports (Mode Interactif)

Le Makefile utilise `lsof` pour scanner les ports avant de lancer le cluster.
* Si le port 8081 est pris, le script se met en pause et vous demande : `👉 Entrez un nouveau port libre :`
* Vous pouvez aussi forcer un port dès le lancement via une variable d'environnement :

`make all HOST_PORT=8085`

### 4. Nettoyage (Clean)

Pour détruire le cluster, supprimer les conteneurs temporaires et nettoyer l'environnement : 
`make clean`

### 5. Détails techniques
* Makefile : orchestrateur. 
* Packer : Utilise le builder `docker` pour créer une image sans registre externe. Il injecte le fichier `src/index.html`
* k3d : Cluster kubernetes léger tournant dans docker. La commande `k3d image import` pour transférer l'image Packer vers le cluster.
* Ansible: 
  * Collection : `kubernetes.core`
  * Ressources : 
    * Deployment : Gère les Pods (ImagePullPolicy: Never).
    * Service : Type ClusterIP.
    * Ingress : Route le trafic HTTP vers le service.










---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 


