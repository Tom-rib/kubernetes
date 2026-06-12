# JOB 02 — Installation K3S (Master + Workers)

**Objectif** : Installer K3S sur les 3 nœuds et former le cluster (1 Master + 2 Workers).

**Durée estimée** : 20 minutes  
**Prérequis** : JOB 01 validé (hostnames, IPs, nftables, sysctl)

---

## 🎯 Architecture du Cluster

```
┌─────────────────────────────────────────┐
│     K3S CONTROL PLANE (Master)          │
│     kubes-01.local (192.168.1.11)       │
│                                         │
│  • API Server (6443)                    │
│  • etcd                                 │
│  • Scheduler                            │
│  • Controller Manager                   │
│  • Kubelet                              │
│  • Containerd                           │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────────┐   ┌───▼────────┐
│  Worker 1  │   │  Worker 2  │
│ kubes-02   │   │ kubes-03   │
│            │   │            │
│ • Kubelet  │   │ • Kubelet  │
│ • Agent    │   │ • Agent    │
│ • Flannel  │   │ • Flannel  │
└────────────┘   └────────────┘
```

---

## 📋 Étapes de l'Installation

### Étape 1 : Installer K3S sur le Master (kubes-01)

```bash
# Sur kubes-01.local (Master)
curl -sfL https://get.k3s.io | sh -
```

**Que fait ce script** :
- Télécharge le binaire K3S
- Configure systemd pour démarrer K3S au boot
- Crée `/etc/rancher/k3s/k3s.yaml` (kubeconfig)
- Démarre le service k3s

**Attendre l'installation** (2-5 minutes) :

```bash
# Vérifier que K3S est prêt
sudo systemctl status k3s

# Vérifier la version
sudo k3s --version

# Vérifier que le cluster se considère comme Ready
sudo k3s kubectl get nodes
```

**Résultat attendu** :

```
NAME       STATUS   ROLES                  AGE   VERSION
kubes-01   Ready    control-plane,master   5m    v1.X.X+k3s1
```

### Étape 2 : Récupérer le Token et l'Adresse du Master

```bash
# Sur kubes-01, récupérer le token du cluster
sudo cat /var/lib/rancher/k3s/server/node-token
```

**Output** : Quelque chose comme `K1234567890abcdef...::server:xxxxxxxx`

Sauvegardez ce token, vous en aurez besoin pour les workers.

```bash
# Récupérer l'adresse IP du master
hostname -I | awk '{print $1}'
```

**Output** : `192.168.1.11` (ou votre adresse IP)

### Étape 3 : Installer K3S sur Worker 1 (kubes-02)

```bash
# Sur kubes-02.local
# Remplacer TOKEN et MASTER_IP par les valeurs du master
export K3S_URL="https://192.168.1.11:6443"
export K3S_TOKEN="K1234567890abcdef...::server:xxxxxxxx"

curl -sfL https://get.k3s.io | sh -
```

**Attendre l'installation** (2-3 minutes) :

```bash
sudo systemctl status k3s-agent
sudo k3s-agent -v  # ou sudo cat /etc/rancher/k3s/k3s-agent.env
```

### Étape 4 : Installer K3S sur Worker 2 (kubes-03)

```bash
# Sur kubes-03.local
export K3S_URL="https://192.168.1.11:6443"
export K3S_TOKEN="K1234567890abcdef...::server:xxxxxxxx"

curl -sfL https://get.k3s.io | sh -
```

### Étape 5 : Vérifier que Tous les Nœuds sont Présents

```bash
# Depuis le Master (kubes-01), lancer :
sudo k3s kubectl get nodes -o wide
```

**Résultat attendu** :

```
NAME       STATUS   ROLES                  AGE   VERSION        INTERNAL-IP   EXTERNAL-IP
kubes-01   Ready    control-plane,master   10m   v1.28.x+k3s1   192.168.1.11  <none>
kubes-02   Ready    <none>                 5m    v1.28.x+k3s1   192.168.1.12  <none>
kubes-03   Ready    <none>                 4m    v1.28.x+k3s1   192.168.1.13  <none>
```

⚠️ Si un nœud reste `NotReady` → consulter la section **Dépannage**.

---

## 🔧 Configuration de kubectl Local

Pour gérer le cluster depuis votre machine locale (optionnel) :

### Sur le Master (kubes-01)

```bash
# Copier la configuration kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

### Sur votre Machine Locale

1. Copier le contenu dans `~/.kube/config`
2. Remplacer `127.0.0.1:6443` par `192.168.1.11:6443` (l'IP du master)

```bash
# Vérifier la connexion
kubectl get nodes
```

---

## 🧪 Tests de Connectivité

### Test 1 : Vérifier la Connexion API

```bash
# Depuis n'importe quel nœud ou localhost
curl -k https://192.168.1.11:6443/version
```

Doit retourner un JSON avec la version K3S.

### Test 2 : Vérifier le Réseau Pod-to-Pod

```bash
# Lancer un pod sur le master
sudo k3s kubectl run test-pod --image=busybox --command -- sleep 3600

# Vérifier qu'il a une IP pod
sudo k3s kubectl get pods -o wide
```

### Test 3 : Vérifier DNS Interne

```bash
# Lancer un pod et faire un DNS lookup
sudo k3s kubectl exec -it test-pod -- nslookup kubernetes.default
```

Doit résoudre `10.43.0.1` (adresse du service kubernetes).

---

## 📊 Vérification Complète (JOB 02)

```bash
# Exécuter depuis le Master
echo "=== NŒUDS CLUSTER ==="
sudo k3s kubectl get nodes

echo "=== NŒUDS DÉTAILLÉS ==="
sudo k3s kubectl get nodes -o wide

echo "=== STATUS NŒUDS ==="
sudo k3s kubectl describe nodes | grep -A 2 "Name:\|Ready"

echo "=== COMPOSANTS K3S ==="
sudo k3s kubectl get pods -A | grep kube

echo "=== VERSION K3S ==="
sudo k3s --version

echo "=== SERVICES K3S ==="
sudo k3s kubectl get services -A

echo "=== STOCKAGE ==="
sudo k3s kubectl get sc  # StorageClasses
```

**Résultat attendu** :
- ✅ 3 nœuds en `Ready`
- ✅ Rôles : `control-plane,master` pour kubes-01
- ✅ Pods du système (coredns, flannel) en `Running`
- ✅ Version K3S v1.28+
- ✅ Services de base présents

---

## 📝 Dépannage JOB 02

### Nœud Reste `NotReady`

**Symptôme** :
```
kubes-02   NotReady   <none>   5m
```

**Solution** :

1. **Vérifier le token** :
```bash
# Le token doit être identique sur master et worker
# Master:
sudo cat /var/lib/rancher/k3s/server/node-token

# Worker:
sudo cat /var/lib/rancher/k3s/agent/node-token
```

2. **Vérifier la connectivité réseau** :
```bash
# Depuis le worker, tenter de joindre le master
nc -zv 192.168.1.11 6443
```

3. **Réinstaller le worker** :
```bash
# Sur le worker
sudo /usr/local/bin/k3s-agent-uninstall.sh  # Désinstaller proprement
# Puis réinstaller avec les bonnes variables
export K3S_URL="https://192.168.1.11:6443"
export K3S_TOKEN="votre_token"
curl -sfL https://get.k3s.io | sh -
```

### Erreur `connection refused` sur port 6443

**Cause** : Master ne répond pas sur le port API.

**Solution** :

```bash
# Sur le master, vérifier que K3S écoute
sudo ss -tulpn | grep 6443

# Redémarrer K3S
sudo systemctl restart k3s

# Vérifier les logs
sudo journalctl -u k3s -n 50
```

### Pods Système en `CrashLoopBackOff`

**Cause** : nftables bloque le trafic inter-nœuds.

**Solution** : Vérifier que nftables autorise les ports K3S (voir JOB 01).

### Nodes voient plusieurs IPs (IPv4 + IPv6)

**Normal** : K3S supporte IPv6. Si vous ne le voulez pas :

```bash
# Ajouter au master:
K3S_CLUSTER_INIT=true
K3S_CLUSTER_SECRET=$(openssl rand -base64 32)

# Et relancer
```

---

## 🛠️ Automatisation (Optionnel)

Le script fourni `scripts/02_install_k3s.sh` automatise tout :

```bash
# Sur chaque nœud
wget https://raw.githubusercontent.com/YOUR-REPO/scripts/02_install_k3s.sh
chmod +x 02_install_k3s.sh

# Maître
sudo ./02_install_k3s.sh master

# Workers
sudo ./02_install_k3s.sh worker 192.168.1.11 K1234567890abcdef...::server:xxxxxxxx
```

---

## ✅ Prêt pour JOB 03 ?

Commandes finales de validation :

```bash
# 1. Tous les nœuds Ready?
sudo k3s kubectl get nodes | grep Ready

# 2. Tous les pods système Running?
sudo k3s kubectl get pods -A | grep -c Running

# 3. Test de pod simple?
sudo k3s kubectl run hello --image=nginx
sudo k3s kubectl get pods
sudo k3s kubectl delete pod hello
```

→ **Suivant** : [JOB 03 — Déployer les Applications](./JOB_03_deployments.md)

---

**Ressources**
- K3S Installation : https://docs.k3s.io/installation
- K3S Token Management : https://docs.k3s.io/installation/installation-requirements#operating-system-and-container-runtime-support
- Kubernetes Nodes : https://kubernetes.io/docs/concepts/architecture/nodes/

**Notes de l'étudiant** :
```
[À remplir lors de la réalisation]
- Master token : _______________________
- Nœuds Ready au bout de : ___ minutes
- IPs obtenues : kubes-01: ___ kubes-02: ___ kubes-03: ___
- Problèmes rencontrés : ___
```
