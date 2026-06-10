# 🏢 Cours 02 - K3S Architecture (1.5 heures)

## 📚 Table des matières
1. [Vue d'ensemble](#vue-densemble)
2. [Différences K3S vs Kubernetes](#différences)
3. [Architecture K3S](#architecture-k3s)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Résumé](#résumé)

---

## 🎯 Vue d'ensemble

### Durée : 1.5 heures
### Niveau : Débutant
### Prérequis : Cours 01

### Objectifs
- ✅ Comprendre les différences K3S vs Kubernetes
- ✅ Maîtriser l'installation K3S
- ✅ Configurer un cluster K3S

---

## 🔄 Différences K3S vs Kubernetes

### Tableau comparatif

| Aspect | Kubernetes | K3S |
|--------|-----------|-----|
| **Taille** | 1.3 GB | 10 MB |
| **RAM requis** | 2GB+ | 512MB |
| **Temps démarrage** | 2-5 min | 30 sec |
| **Binaires** | Multiples | 1 seul |
| **Storage** | etcd | SQLite (ou etcd) |
| **CNI inclus** | Non | Flannel |
| **Ingress inclus** | Non | Traefik |
| **Cible** | Data centers | Edge, IoT, Dev |
| **Complexité** | Haute | Basse |

### Quand utiliser quoi ?

**Kubernetes complet** :
```
✅ Production scale
✅ Multi-clouds
✅ High availability 24/7
✅ Équipe DevOps expérimentée
✅ Features avancées requises
```

**K3S** :
```
✅ Apprentissage
✅ Edge computing
✅ IoT devices
✅ Single machine
✅ Prototypes rapides
✅ CI/CD léger
```

---

## 🏗️ Architecture K3S

### Vue d'ensemble

```
K3S (monolithique)
├─ k3s server (master)
│  ├─ API Server
│  ├─ etcd (ou SQLite)
│  ├─ Controller Manager
│  ├─ Scheduler
│  ├─ local-path-provisioner
│  └─ Traefik (ingress)
│
└─ k3s agent (worker)
   ├─ kubelet
   ├─ kube-proxy
   └─ flannel (CNI)
```

### Avantages de l'approche monolithique

```
Kubernetes classique (6 binaires)
├─ kube-apiserver
├─ etcd
├─ kube-controller-manager
├─ kube-scheduler
├─ kubelet
└─ kube-proxy

K3S (1 binaire)
└─ k3s (contient tout)
   └─ 40 MB seulement !
```

### Storage dans K3S

**Par défaut : SQLite**
```
K3S sans flags
    ↓
Stockage local SQLite
├─ Fichier : /var/lib/rancher/k3s/server/db/state.db
├─ Léger
├─ Pas de clustering
└─ Parfait pour single-node
```

**Alternative : etcd**
```bash
# Installer K3S avec etcd
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--datastore-endpoint=https://etcd:2379" sh -
```

**Avantage** : Multi-node clustering

### Network Plugins

**K3S inclut Flannel par défaut**
```
Flannel = Simple overlay network
├─ Vxlan backend
├─ Configuration simple
└─ Performance correcte pour dev/test

Changeable par :
├─ Weave
├─ Calico
└─ Cilium
```

### Ingress dans K3S

**K3S inclut Traefik par défaut**
```
Traefik
├─ Moderne et rapide
├─ Configuration simple
├─ Peut remplacer nginx-ingress
└─ Inclus ! (pas besoin d'installation)
```

---

## 📥 Installation

### Installation One-Liner (Magique !)

```bash
curl -sfL https://get.k3s.io | sh -
```

**Que fait cette commande ?**

```
1. Télécharge le script get.k3s.io
2. Récupère la dernière version du binaire k3s
3. Installe dans /usr/local/bin/
4. Crée systemd service
5. Démarre k3s
6. Configure kubeconfig dans ~/.kube/config
```

**En 30 secondes, vous avez un cluster Kubernetes complet !** 🚀

### Installation Détaillée

```bash
# 1. Télécharger et installer
curl -sfL https://get.k3s.io | sh -

# 2. Vérifier le statut
systemctl status k3s

# 3. Vérifier kubectl
kubectl get nodes

# 4. Récupérer le token (pour workers)
cat /var/lib/rancher/k3s/server/node-token

# 5. Afficher kubeconfig
cat /etc/rancher/k3s/k3s.yaml
```

### Installation sur Worker

```bash
# Sur le worker
K3S_URL=https://<master-ip>:6443 \
K3S_TOKEN=<token-from-master> \
curl -sfL https://get.k3s.io | sh -

# Vérifier depuis master
kubectl get nodes
# Output : master et worker listés
```

### Options d'installation courantes

```bash
# Désactiver Traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Désactiver certains composants
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --disable=coredns" sh -

# Utiliser etcd au lieu de SQLite
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--datastore-endpoint=https://etcd" sh -

# Configuration réseau personnalisée
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--cluster-cidr=10.0.0.0/8" sh -
```

---

## ⚙️ Configuration

### Fichier de configuration K3S

**Location** : `/etc/rancher/k3s/k3s.yaml`

```yaml
apiVersion: v1
clusters:
- cluster:
    server: https://127.0.0.1:6443
  name: k3s
contexts:
- context:
    cluster: k3s
    user: admin@k3s
  name: k3s
current-context: k3s
kind: Config
users:
- name: admin@k3s
  user:
    client-certificate-data: ...
    client-key-data: ...
```

### Kubeconfig sur machine locale

```bash
# Copier depuis le serveur K3S
scp root@<k3s-server>:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Éditer pour changer localhost par IP
sed -i 's/127.0.0.1/<k3s-server-ip>/g' ~/.kube/config

# Vérifier
kubectl get nodes
```

### Répertoires importants

```
/var/lib/rancher/k3s/
├─ server/          (master data)
│  ├─ db/           (etcd ou SQLite)
│  ├─ logs/
│  └─ manifests/    (auto-deployed)
├─ agent/           (worker data)
├─ data/            (sharedpersistent)
└─ server.log
```

### Logs K3S

```bash
# Voir les logs
journalctl -u k3s -f

# Ou fichier log
tail -f /var/log/k3s.log

# Sur worker
journalctl -u k3s-agent -f
```

---

## 🚀 Commandes essentielles

### Démarrer/Arrêter

```bash
# Démarrer K3S
systemctl start k3s
systemctl start k3s-agent (worker)

# Arrêter
systemctl stop k3s

# Statut
systemctl status k3s

# Auto-start au démarrage
systemctl enable k3s
```

### Vérifier l'installation

```bash
# Version
k3s --version
kubectl version

# Nœuds
kubectl get nodes

# Pods système
kubectl get pods -n kube-system

# Composants
kubectl get components
```

### Désinstaller K3S

```bash
# Master
/usr/local/bin/k3s-uninstall.sh

# Worker
/usr/local/bin/k3s-agent-uninstall.sh
```

---

## 🔐 Sécurité K3S

### Par défaut sécurisé

K3S inclut :
- ✓ RBAC activé
- ✓ Service accounts
- ✓ Network policies supportées
- ✓ Secrets chiffrés

### Accès API

```bash
# API Server écoute sur
# https://127.0.0.1:6443

# Accès avec kubeconfig
kubectl get pods
# Utilise le cert dans kubeconfig

# Accès avec token
kubectl --token=<token> get pods
```

### Sauvegarder le cluster

```bash
# Sauvegarder la base de données
sudo k3s server --snapshots-dir=/backup

# Ou manuellement
sudo cp /var/lib/rancher/k3s/server/db/state.db /backup/
```

---

## 📊 Monitoring K3S

### Vérifier les ressources

```bash
# CPU et mémoire
kubectl top nodes
kubectl top pods --all-namespaces

# Note : Nécessite metrics-server
kubectl get deployment metrics-server -n kube-system
```

### Logs des problèmes

```bash
# Pod ne démarre pas
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Événements
kubectl get events --all-namespaces

# Débugging
kubectl exec -it <pod> -- /bin/bash
```

---

## 🎯 Comparaison : Installation K3S vs Kubernetes

### Installation K3S (5 minutes)

```bash
curl -sfL https://get.k3s.io | sh -
# Done !
```

### Installation Kubernetes (1-2 heures)

```bash
# Télécharger les binaires
# Configurer TLS
# Installer etcd
# Configurer API server
# Installer kubelet
# Configurer CNI
# Configurer RBAC
# ...
# (Et c'est juste le master)
```

### Pourquoi K3S est plus facile ?

```
K3S = Kubernetes - Complexité
    = Kubernetes sans :
    - Choix de storage (SQLite)
    - Choix de CNI (Flannel)
    - Choix d'ingress (Traefik)
    - Binaires séparés (tout dans k3s)
    = Défauts sensés + Installation simple
```

---

## 📝 Configuration Recommandée

### Pour développement

```bash
# Single node, SQLite
curl -sfL https://get.k3s.io | sh -
```

### Pour staging

```bash
# Multi-node, SQLite
Master :
curl -sfL https://get.k3s.io | sh -

Worker 1 & 2 :
K3S_URL=https://master:6443 K3S_TOKEN=... \
curl -sfL https://get.k3s.io | sh -
```

### Pour production

```bash
# Multi-node, etcd
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="--datastore-endpoint=https://etcd:2379" \
sh -
```

---

## ⚠️ Limitations K3S

```
❌ Pas de HA automatique (multi-master)
   → Utilisez etcd clustering

❌ Storage local seulement (par défaut)
   → Utilisez volumes externes

❌ Pas de service mesh inclus
   → Installez Istio si nécessaire

❌ Métriques basiques
   → Installez Prometheus pour plus
```

---

## 📋 Résumé

### À retenir

- K3S = Kubernetes simplifié et léger
- Installation en 1 ligne de commande
- Parfait pour l'apprentissage et edge computing
- 100% compatible Kubernetes

### Architecture K3S

```
Master (k3s server)
├─ k3s binary (40 MB)
├─ API Server + etcd (ou SQLite)
├─ Traefik (ingress)
└─ Local storage provisioner

Worker (k3s agent)
├─ k3s-agent
├─ kubelet + kube-proxy
└─ Flannel (CNI)
```

### Installation

```bash
# Master
curl -sfL https://get.k3s.io | sh -

# Worker
K3S_URL=https://master:6443 K3S_TOKEN=... curl -sfL https://get.k3s.io | sh -
```

---

## 🧪 Quiz d'auto-évaluation

- [ ] Je comprends les différences K3S vs Kubernetes
- [ ] Je peux installer K3S en 1 ligne
- [ ] Je sais joindre un worker au cluster
- [ ] Je comprends la structure K3S
- [ ] Je peux configurer kubeconfig localement

**Si tout est coché, vous maîtrisez K3S !** ✅

---

## 📚 Pour approfondir

- Lire : `03_docker_images.md` (Images de base)
- Pratiquer : Installer K3S multi-node
- Consulter : https://docs.k3s.io/

---

*Fin du cours 02. Vous maîtrisez K3S ! 🎉*
