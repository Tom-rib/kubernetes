# 02 - Installation K3S (Job 01)

## 🎯 Objectif
Installer **K3S** (distribution légère de Kubernetes) sur chaque VM Debian et valider le fonctionnement indépendant de chaque nœud.

## 📋 Table des matières
1. [Qu'est-ce que K3S ?](#quest-ce-que-k3s)
2. [Prérequis](#prérequis)
3. [Installation K3S](#installation-k3s)
4. [Configuration kubelet](#configuration-kubelet)
5. [Vérification](#vérification)
6. [Documentation des commandes](#documentation-des-commandes)

---

## 💡 Qu'est-ce que K3S ?

**K3S** est une distribution **ultra-légère** de Kubernetes :
- ✅ **Taille** : ~5-10 MB (vs 1.3 GB pour Kubernetes complet)
- ✅ **Ressources** : 512 MB RAM min (vs 2 GB pour K8s)
- ✅ **Installation** : 30 secondes
- ✅ **Maintenance** : Un seul binaire (`k3s`)
- ✅ **Production-ready** : Certifié Kubernetes conforme

**Idéal pour** : Labs, IoT, edge computing, apprentissage

### Comparaison

| Aspect | Kubernetes | K3S | Docker Swarm |
|--------|-----------|-----|--------------|
| Taille | 1.3 GB | 10 MB | 50 MB |
| Complexité | Élevée | Faible | Très faible |
| Scalabilité | Clusters très gros | Petits clusters | Petits clusters |
| Learning curve | Steepe | Faible | Très faible |
| Production | ✓ | ✓ | ✗ |

---

## ✅ Prérequis

Avant d'installer K3S, assurez-vous que :

### Prérequis système
```bash
# ✓ OS : Debian 11, 12 ou Ubuntu 22.04+
# ✓ Swap : Désactivée (voir 01_preparation.md)
# ✓ Réseau : Connectée avec IP statique
# ✓ SSH : Accessible
# ✓ RAM : 2 GB minimum
# ✓ CPU : 2 cœurs minimum
# ✓ Firewall : Ports 6443, 10250, 10255 ouverts
```

### Vérifier avant de commencer

```bash
# 1. Pas de swap
free -m | grep Swap
# Swap should show 0 for total

# 2. Connectivité réseau
ping 8.8.8.8

# 3. Permissions sudo
sudo whoami
# Should return : root

# 4. Kernel version
uname -r
# Should be 4.4 or higher
```

---

## 🚀 Installation K3S

### Étape 1 : Installation du serveur K3S

**Sur la VM kubes-01 (ou la première VM)** :

```bash
# Télécharger et exécuter le script d'installation
curl -sfL https://get.k3s.io | sh -

# Ou si vous voulez spécifier une version
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.0 sh -
```

**Que fait ce script ?**
```
1. Télécharge le binaire K3S
2. Installe K3S dans /usr/local/bin/
3. Crée les répertoires de config
4. Démarre le service K3S
5. Configure les permissions
```

### Étape 2 : Vérifier l'installation

```bash
# Vérifier que K3S tourne
sudo systemctl status k3s

# Afficher la version
k3s --version

# Vérifier les nœuds
sudo k3s kubectl get nodes

# Vérifier les pods système
sudo k3s kubectl get pods -A
```

### Étape 3 : Configurer l'accès kubectl

Par défaut, les commandes `kubectl` nécessitent `sudo`. Pour faciliter :

```bash
# Option 1 : Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Option 2 : Créer un alias (plus simple)
echo "alias kubectl='sudo k3s kubectl'" >> ~/.bashrc
source ~/.bashrc

# Option 3 : Copier le kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Vérifier que ça marche
kubectl get nodes
```

### Étape 4 : Récupérer le token pour les workers

Sur **kubes-01**, récupérer le token pour joindre le cluster :

```bash
# Afficher le token (sauvegardez-le !)
sudo cat /var/lib/rancher/k3s/server/node-token

# Exemple de sortie :
# K10abcdef123456...XYZ::server:xyz123...

# Sauvegarder le token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo "Token: $TOKEN"

# Sauvegarder aussi l'URL du serveur
MASTER_URL="https://kubes-01.local:6443"
echo "Master URL: $MASTER_URL"
```

---

## 🔧 Configuration kubelet

### Étape 1 : Configuration de base

Le fichier de config de K3S se trouve à :
```bash
cat /etc/rancher/k3s/k3s.yaml
```

### Étape 2 : Vérifier la configuration réseau

```bash
# Afficher l'interface réseau K3S
sudo k3s kubectl get nodes -o wide

# Vérifier les services
sudo k3s kubectl get svc -A

# Afficher les logs
sudo journalctl -u k3s -f

# Ou via systemd
sudo systemctl logs k3s --no-paging
```

### Étape 3 : Configurer les ports pare-feu

```bash
# UFW
sudo ufw allow 6443/tcp   # API Server
sudo ufw allow 10250/tcp  # Kubelet
sudo ufw allow 10255/tcp  # Kubelet read-only

# iptables
sudo iptables -I INPUT -p tcp --dport 6443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 10250 -j ACCEPT

# Sauvegarder les règles iptables
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

---

## ✅ Vérification

### Test 1 : K3S est installé et fonctionne

```bash
# Vérifier le service
sudo systemctl status k3s
# Expected output: active (running)

# Vérifier les processes
ps aux | grep k3s | grep -v grep
# Devrait afficher : /usr/local/bin/k3s server
```

### Test 2 : Kubectl fonctionne

```bash
kubectl version
# Affiche la version du client et du serveur

kubectl cluster-info
# Affiche les infos du cluster
```

### Test 3 : Les nœuds sont vus

```bash
kubectl get nodes
# Expected output:
# NAME       STATUS   ROLES                  AGE   VERSION
# kubes-01   Ready    control-plane,master   1m    v1.28.0
```

### Test 4 : Les pods système tournent

```bash
kubectl get pods -A
# Affiche les pods système (kube-system, default)

# Exemple de résultat :
# NAMESPACE     NAME                                      READY   STATUS    RESTARTS
# kube-system   coredns-54467db7fc-xyz                    1/1     Running   0
# kube-system   local-path-provisioner-84db7d9bc9        1/1     Running   0
```

### Test 5 : Déployer un pod de test

```bash
# Créer un simple pod Nginx pour tester
kubectl run nginx-test --image=nginx:latest --port=80

# Vérifier que le pod tourne
kubectl get pods
# Attendez quelques secondes

# Voir les logs
kubectl logs nginx-test

# Nettoyer
kubectl delete pod nginx-test
```

---

## 📋 Exemple complet d'installation (une seule VM)

Voici le déroulement complet sur **kubes-01** :

```bash
#!/bin/bash
echo "========== INSTALLATION K3S =========="

# 1. Vérifier les prérequis
echo "1. Vérification des prérequis..."
echo "   - Swap: $(free -m | grep Swap | awk '{print $2}') MB"
echo "   - RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "   - CPU: $(nproc)"

# 2. Installer K3S
echo "2. Installation K3S..."
curl -sfL https://get.k3s.io | sh -
sleep 5

# 3. Vérifier l'installation
echo "3. Vérification..."
sudo systemctl status k3s --no-pager
k3s --version

# 4. Configurer kubectl
echo "4. Configuration kubectl..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# 5. Tester
echo "5. Tests..."
kubectl version
kubectl get nodes
kubectl get pods -A

# 6. Récupérer le token
echo "6. Token pour workers:"
sudo cat /var/lib/rancher/k3s/server/node-token

echo "========== K3S PRÊT =========="
```

---

## 📝 Documentation des commandes

### Installer K3S
```bash
curl -sfL https://get.k3s.io | sh -
```
**Que fait :** Télécharge et installe K3S en tant que service systemd

### Démarrer/arrêter K3S
```bash
sudo systemctl start k3s
sudo systemctl stop k3s
sudo systemctl restart k3s
sudo systemctl status k3s
```

### Voir les logs
```bash
sudo journalctl -u k3s -f        # Logs en temps réel
sudo journalctl -u k3s --no-paging | tail -50  # Derniers logs
sudo systemctl logs k3s
```

### Interroger le cluster
```bash
kubectl version               # Version K8s
kubectl cluster-info          # Infos cluster
kubectl get nodes             # Nœuds du cluster
kubectl get pods -A           # Tous les pods
kubectl get namespaces        # Namespaces
```

### Accéder à kubeconfig
```bash
cat ~/.kube/config            # Affiche le config
kubectl config current-context # Contexte actuel
kubectl config get-contexts   # Tous les contextes
```

---

## 🔄 Répéter sur les autres VMs

**Sur kubes-02 et kubes-03**, exécutez les mêmes étapes (1 et 2 seulement - les étapes 3-5 se feront à l'étape suivante).

Pour rappel, sur chaque VM :

```bash
# 1. Installation
curl -sfL https://get.k3s.io | sh -

# 2. Configuration kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# 3. Vérification
kubectl version
kubectl get nodes
```

**À ce stade, chaque VM a K3S indépendant.**
**À l'étape suivante, nous les mettrons en cluster.**

---

## 📊 État attendu après cette étape

| Élément | Kubes-01 | Kubes-02 | Kubes-03 |
|---------|----------|----------|----------|
| K3S installé | ✓ | ✓ | ✓ |
| Service K3S actif | ✓ | ✓ | ✓ |
| Kubectl fonctionne | ✓ | ✓ | ✓ |
| Pods système | ✓ | ✓ | ✓ |
| Token récupéré | ✓ | - | - |

---

## ⚠️ Points d'attention

- ⚠️ **Swap** : Doit être désactivée (voir 01_preparation.md)
- ⚠️ **Token** : Sauvegardez-le, vous en aurez besoin pour les workers
- ⚠️ **Firewall** : Ouvrez les ports 6443, 10250, 10255
- ⚠️ **Kubeconfig** : Sauvegardez ~/.kube/config

---

## 🐛 Dépannage

### Problème : K3S n'a pas démarré
```bash
# Vérifier le service
sudo systemctl status k3s

# Vérifier les logs
sudo journalctl -u k3s | tail -50

# Redémarrer
sudo systemctl restart k3s

# Réinstaller
curl -sfL https://get.k3s.io | sh -
```

### Problème : kubectl ne trouve pas le serveur
```bash
# Vérifier kubeconfig
cat ~/.kube/config

# Recréer kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### Problème : Port 6443 déjà utilisé
```bash
# Vérifier quel processus utilise le port
sudo lsof -i :6443
sudo netstat -tlnp | grep 6443

# Arrêter K3S et réessayer
sudo systemctl stop k3s
curl -sfL https://get.k3s.io | sh -
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ K3S installé sur kubes-01, kubes-02, kubes-03
- ✓ Chaque nœud a son propre cluster K3S
- ✓ kubectl fonctionne sur chaque nœud
- ✓ Token du master sauvegardé

**Passez à : `03_applications_conteneurisees.md`** pour déployer nginx, Apache, MariaDB sur chaque VM.

---

## 📝 Journal de bord

Documentez ici vos étapes d'installation :

```
Date : [date]
VM kubes-01 :
  - K3S version : [version]
  - Installation time : [temps]
  - Status : [OK/NOK]
  - Token : [token]

VM kubes-02 :
  - K3S version : [version]
  - Status : [OK/NOK]

VM kubes-03 :
  - K3S version : [version]
  - Status : [OK/NOK]

Problèmes rencontrés :
  - [problème 1] → [solution]
  - [problème 2] → [solution]
```

---

**✅ K3S est installé ! Prêt pour les applications conteneurisées.**
