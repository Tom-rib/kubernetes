# 🚀 Scripts K3S

Tous les scripts bash pour automatiser le déploiement du cluster K3S.

## 📋 Scripts Disponibles

### 01_setup_debian.sh
**Préparation de la VM Debian Trixie**

```bash
sudo chmod +x 01_setup_debian.sh
sudo ./01_setup_debian.sh
```

**Installe** :
- Mises à jour système
- Kernel modules (br_netfilter, overlay)
- sysctl K3S
- nftables firewall (Debian Trixie)
- Désactive le swap

**Durée** : ~5 minutes

---

### 02_install_k3s.sh
**Installation K3S (Master ou Worker)**

Master :
```bash
sudo chmod +x 02_install_k3s.sh
sudo ./02_install_k3s.sh master
```

Workers :
```bash
sudo ./02_install_k3s.sh worker 192.168.1.11 K1234567890abcdef...::server:xxxxxxxx
```

**Installe** :
- K3S Server (Master)
- K3S Agent (Worker)
- Jointure automatique au cluster

**Durée** : ~5 minutes par nœud

---

### 04_deploy_apps.sh
**Déploiement des applications (Nginx, Apache, MariaDB)**

```bash
sudo chmod +x 04_deploy_apps.sh
sudo ./04_deploy_apps.sh
```

**Crée** :
- Deployment Nginx (3 replicas)
- Deployment Apache (2 replicas)
- Deployment MariaDB (1 replica)
- Services NodePort pour Nginx/Apache
- Service ClusterIP pour MariaDB

**Durée** : ~2 minutes

---

### 05_test_ha.sh
**Tests de Haute Disponibilité**

```bash
sudo chmod +x 05_test_ha.sh
sudo ./05_test_ha.sh
```

**Teste** :
- Self-healing (suppression de pod)
- Load balancing (10 requêtes)
- ReplicaSet
- Distribution inter-nœuds
- Événements cluster

**Durée** : ~2 minutes

---

## 🔄 Workflow Complet

### 1. Sur chaque VM (kubes-01, kubes-02, kubes-03)

```bash
# Copier le script
wget https://raw.githubusercontent.com/YOUR-REPO/scripts/01_setup_debian.sh
chmod +x 01_setup_debian.sh

# Exécuter
sudo ./01_setup_debian.sh
```

### 2. Sur le Master (kubes-01)

```bash
wget https://raw.githubusercontent.com/YOUR-REPO/scripts/02_install_k3s.sh
chmod +x 02_install_k3s.sh
sudo ./02_install_k3s.sh master

# Récupérer le token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(hostname -I | awk '{print $1}')
echo "Token: $TOKEN"
echo "Master IP: $MASTER_IP"
```

### 3. Sur les Workers (kubes-02, kubes-03)

```bash
chmod +x 02_install_k3s.sh
sudo ./02_install_k3s.sh worker 192.168.1.11 K1234567890abcdef...::server:xxxxxxxx
```

### 4. Vérifier le cluster

```bash
# Depuis le master
sudo k3s kubectl get nodes
# Doit afficher 3 nœuds Ready
```

### 5. Déployer les apps

```bash
chmod +x 04_deploy_apps.sh
sudo ./04_deploy_apps.sh
```

### 6. Tester la HA

```bash
chmod +x 05_test_ha.sh
sudo ./05_test_ha.sh
```

---

## 🛠️ Dépannage

### Script échoue avec "Permission denied"
```bash
chmod +x script_name.sh
```

### Script échoue avec "curl: (7) Failed to connect"
- Vérifier la connectivité réseau (`ping 8.8.8.8`)
- Vérifier que nftables permet HTTPS (port 443)

### K3S ne démarre pas
```bash
sudo systemctl status k3s
sudo journalctl -u k3s -n 50
```

### Worker n'est pas en Ready
```bash
# Sur le worker
sudo systemctl status k3s-agent
sudo journalctl -u k3s-agent -n 50

# Vérifier la connectivité
nc -zv 192.168.1.11 6443
```

---

## ✅ Checklist Automatisation

- [x] 01_setup_debian.sh → Prêt
- [x] 02_install_k3s.sh → Prêt
- [x] 04_deploy_apps.sh → Prêt
- [x] 05_test_ha.sh → Prêt
- [ ] Helm setup script (bonus)
- [ ] Backup/restore script (bonus)

---

## 📚 Ressources

- K3S Docs : https://docs.k3s.io/
- Installation : https://docs.k3s.io/installation/installation-requirements
- Cluster Access : https://docs.k3s.io/cluster-access

