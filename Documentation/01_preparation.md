# 01 - Préparation et Prérequis

## 🎯 Objectif
Configurer l'environnement de base : 3 VMs Debian, réseau, accès SSH, et valider les prérequis avant l'installation de K3S.

## 📋 Table des matières
1. [Prérequis matériels](#prérequis-matériels)
2. [Prérequis logiciels](#prérequis-logiciels)
3. [Architecture et schéma réseau](#architecture-et-schéma-réseau)
4. [Création des VMs](#création-des-vms)
5. [Configuration réseau](#configuration-réseau)
6. [Validation des prérequis](#validation-des-prérequis)

---

## 🖥️ Prérequis matériels

### Configuration minimale par VM

| Ressource | Minimale | Recommandée |
|-----------|----------|-------------|
| **Processeur (CPU)** | 2 cœurs | 4 cœurs |
| **Mémoire RAM** | 2 GB | 4+ GB |
| **Disque dur** | 20 GB | 40+ GB |
| **Réseau** | 1 interface | 2 interfaces |

### Configuration totale du cluster
- **3 VMs Debian** (pas de GUI)
- **Hyperviseur** : KVM/QEMU, VirtualBox, VMware, ou Proxmox
- **Réseau** : Bridge ou NAT avec IP statiques
- **Accès SSH** : Configuré pour chaque VM

---

## 📦 Prérequis logiciels

### OS requis
```bash
Debian 11, 12 (Bullseye, Bookworm) ou Ubuntu 22.04+
```

### Logiciels à avoir sur le poste client (hôte)
```bash
- Hyperviseur (VirtualBox, KVM, Proxmox, etc.)
- Client SSH (ssh, PuTTY, MobaXterm)
- Outil de gestion : terraform, vagrant (optionnel)
- kubectl (client Kubernetes) - installé plus tard
```

### Logiciels à installer sur les VMs
```bash
- curl
- wget
- git
- net-tools
- openssh-server
- sudo
- vim / nano
- htop
```

---

## 🏗️ Architecture et schéma réseau

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                    RÉSEAU: 10.0.0.0/24                      │
│                   (ou 192.168.1.0/24)                       │
└─────────────────────────────────────────────────────────────┘
    │
    ├── 🖥️  kubes-01.local (10.0.0.10)
    │        Role: MASTER
    │        CPU: 2-4, RAM: 4-8GB, Disk: 40GB
    │        Services: API Server, etcd, Controller Manager
    │
    ├── 🖥️  kubes-02.local (10.0.0.11)
    │        Role: WORKER
    │        CPU: 2-4, RAM: 4-8GB, Disk: 40GB
    │        Services: kubelet, kube-proxy
    │
    └── 🖥️  kubes-03.local (10.0.0.12)
             Role: WORKER
             CPU: 2-4, RAM: 4-8GB, Disk: 40GB
             Services: kubelet, kube-proxy
```

### Plan d'adressage

| Hostname | IP interne | Role | RAM | CPU |
|----------|-----------|------|-----|-----|
| **kubes-01.local** | 10.0.0.10 | Master | 4-8 GB | 2-4 |
| **kubes-02.local** | 10.0.0.11 | Worker | 4-8 GB | 2-4 |
| **kubes-03.local** | 10.0.0.12 | Worker | 4-8 GB | 2-4 |
| **DNS/Gateway** | 10.0.0.1 | - | - | - |

---

## 🚀 Création des VMs

### Option 1 : Création manuelle

#### Étape 1 : Créer la première VM (kubes-01)

1. **Dans votre hyperviseur** (VirtualBox, Proxmox, etc.) :
   - Créer une nouvelle VM
   - **Nom** : `kubes-01`
   - **CPU** : 2-4 cœurs
   - **RAM** : 4-8 GB
   - **Disque** : 40 GB (format qcow2 ou VDI)
   - **Réseau** : Bridge (ou NAT)
   - **ISO** : Debian 12 Bookworm (minimal/netinstall)

2. **Installation de Debian** :
   ```
   Langue : Français / Anglais
   Clavier : AZERTY / QWERTY
   Fuseau horaire : Europe/Paris
   Partitionnement : Automatique (LVM recommandé)
   Hostname : kubes-01.local
   Domaine : local (ou votre domaine)
   Root password : [définir un mot de passe fort]
   Créer utilisateur : student / [mot de passe]
   Paquets : décocher "Bureau Debian", garder "Utilitaires système"
   ```

3. **Après redémarrage initial** :
   - Se connecter avec `student` ou `root`
   - Configurer l'IP statique (voir section suivante)

#### Étape 2 : Dupliquer pour kubes-02 et kubes-03

1. **Cloner la VM** (à partir de kubes-01)
2. **Renommer** en `kubes-02` et `kubes-03`
3. **Modifier l'IP statique** pour chacune
4. **Changer le hostname** pour chacune

### Option 2 : Script d'automatisation (Terraform / Vagrant)

Si vous avez accès à Terraform ou Vagrant, voir `scripts/01_setup_vms.sh`.

---

## 🌐 Configuration réseau

### 1. Définir l'IP statique sur chaque VM

**Méthode 1 : nmtui (NetworkManager - GUI)**

```bash
# Si NetworkManager est installé
sudo nmtui
```

**Méthode 2 : Éditer directement la configuration**

Pour **Debian 12 (Bookworm)** avec `systemd-networkd` :

```bash
sudo nano /etc/network/interfaces
```

Ajouter :
```conf
# kubes-01
auto eth0
iface eth0 inet static
  address 10.0.0.10
  netmask 255.255.255.0
  gateway 10.0.0.1
  dns-nameservers 8.8.8.8 8.8.4.4
```

Ou avec **netplan** (Debian 11+) :

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 10.0.0.10/24      # Changer pour chaque VM
      routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
  version: 2
```

Appliquer les changements :
```bash
sudo netplan apply
```

### 2. Définir le hostname

```bash
# Afficher le hostname actuel
hostname

# Le modifier temporairement
sudo hostname kubes-01.local

# Le modifier définitivement
sudo nano /etc/hostname
# Ajouter : kubes-01.local

# Éditer aussi /etc/hosts
sudo nano /etc/hosts
# Ajouter :
# 10.0.0.10   kubes-01.local kubes-01
# 10.0.0.11   kubes-02.local kubes-02
# 10.0.0.12   kubes-03.local kubes-03
```

### 3. Redémarrer le réseau

```bash
sudo systemctl restart networking
# ou
sudo reboot
```

### 4. Vérifier la connectivité

```bash
# Afficher l'IP
ip addr show

# Tester la connectivité
ping 10.0.0.1      # Gateway
ping 8.8.8.8       # DNS public

# Résoudre les noms
nslookup kubes-02.local
```

---

## 🔑 Configuration SSH

### 1. Installer SSH Server (si pas déjà installé)

```bash
sudo apt update
sudo apt install openssh-server openssh-client

# Vérifier que SSH est actif
sudo systemctl status ssh
sudo systemctl enable ssh  # Activer au démarrage
```

### 2. Configurer SSH pour accès sans mot de passe (clés)

**Sur votre poste client (hôte)** :

```bash
# Générer une paire de clés (si vous n'en avez pas)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copier la clé publique sur chaque VM
ssh-copy-id -i ~/.ssh/id_rsa.pub student@10.0.0.10
ssh-copy-id -i ~/.ssh/id_rsa.pub student@10.0.0.11
ssh-copy-id -i ~/.ssh/id_rsa.pub student@10.0.0.12
```

**Ou manuellement sur chaque VM** :

```bash
# Sur la VM
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Coller le contenu de ~/.ssh/id_rsa.pub du client dans :
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. Tester la connexion SSH

```bash
ssh student@kubes-01.local
ssh student@kubes-02.local
ssh student@kubes-03.local

# Ou avec IP
ssh student@10.0.0.10
```

---

## ✅ Validation des prérequis

### Checklist avant d'aller plus loin

Exécutez cette commande sur chaque VM :

```bash
#!/bin/bash
echo "=== VÉRIFICATION DES PRÉREQUIS ==="

# 1. Vérifier l'OS
echo "1. Version de Debian :"
cat /etc/os-release | grep PRETTY_NAME

# 2. Vérifier les ressources
echo -e "\n2. Ressources disponibles :"
echo "CPU : $(nproc) cœurs"
echo "RAM : $(free -h | grep Mem | awk '{print $2}')"
echo "Disque : $(df -h / | tail -1 | awk '{print $2}')"

# 3. Vérifier les logiciels requuis
echo -e "\n3. Logiciels installés :"
which curl && echo "✓ curl" || echo "✗ curl"
which wget && echo "✓ wget" || echo "✗ wget"
which git && echo "✓ git" || echo "✗ git"
which ssh && echo "✓ ssh" || echo "✗ ssh"
which sudo && echo "✓ sudo" || echo "✗ sudo"

# 4. Vérifier la connectivité réseau
echo -e "\n4. Connectivité réseau :"
ping -c 1 -W 1 8.8.8.8 > /dev/null && echo "✓ Internet" || echo "✗ Internet"
ping -c 1 -W 1 10.0.0.1 > /dev/null && echo "✓ Gateway" || echo "✗ Gateway"

# 5. Vérifier le hostname
echo -e "\n5. Hostname :"
hostname

# 6. Vérifier les permissions
echo -e "\n6. Permissions sudo :"
sudo -n echo "✓ Accès sudo" 2>/dev/null || echo "✗ Accès sudo"

echo -e "\n=== FIN DE LA VÉRIFICATION ==="
```

Sauvegarder ce script :
```bash
cat > ~/check_prereq.sh << 'EOF'
[coller le script ci-dessus]
EOF

chmod +x ~/check_prereq.sh
./check_prereq.sh
```

### Résultats attendus

✅ **Tous les points verts** :
```
✓ curl, wget, git, ssh, sudo
✓ Debian 12 ou 11
✓ 2+ CPU, 2+ GB RAM
✓ Internet et Gateway accessibles
✓ Hostname correctement défini
✓ Sudo configuré
```

---

## 📝 Installation des outils de base

Sur chaque VM, installer les outils utiles :

```bash
sudo apt update
sudo apt upgrade -y

# Utilitaires système
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  nano \
  htop \
  net-tools \
  dnsutils \
  telnet \
  iputils-ping

# Pour K3S, installer aussi :
sudo apt install -y \
  iptables \
  ebtables \
  ethtool
```

---

## 🔐 Sécurité de base

### 1. Configurer le pare-feu (UFW)

```bash
sudo apt install -y ufw

# Autoriser SSH (IMPORTANT - sinon vous serez bloqué !)
sudo ufw allow 22/tcp

# Pour K3S, autoriser les ports
sudo ufw allow 6443/tcp     # Kubernetes API
sudo ufw allow 10250/tcp    # Kubelet
sudo ufw allow 10255/tcp    # Kubelet read-only
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS

# Activer le pare-feu
sudo ufw enable
sudo ufw status
```

### 2. Désactiver la mémoire virtuelle (swap) pour Kubernetes

```bash
# Vérifier la swap
free -m | grep Swap

# Désactiver temporairement
sudo swapoff -a

# Désactiver définitivement
sudo nano /etc/fstab
# Commenter la ligne swap

# Vérifier
free -m | grep Swap
```

---

## 📊 Tableau récapitulatif

| Élément | Valeur | Status |
|---------|--------|--------|
| **OS** | Debian 12 | ✓ |
| **Hostname kubes-01** | kubes-01.local | ✓ |
| **IP kubes-01** | 10.0.0.10 | ✓ |
| **SSH accessible** | Yes | ✓ |
| **Internet accessible** | Yes | ✓ |
| **CPU minimum** | 2 | ✓ |
| **RAM minimum** | 2 GB | ✓ |
| **Swap** | Désactivée | ✓ |
| **Outils basiques** | curl, git, etc. | ✓ |

---

## ⚠️ Points d'attention

- ⚠️ **Ne pas oublier le SSH** - vous risquez de ne plus avoir accès !
- ⚠️ **Désactiver la swap** - Kubernetes le demande explicitement
- ⚠️ **Sauvegarder les IPs** - vous en aurez besoin plus tard
- ⚠️ **Tester la connectivité** avant de continuer
- ⚠️ **Clés SSH** - facilitent grandement les déploiements

---

## 📚 Prochaines étapes

Une fois que :
- ✓ 3 VMs Debian sont créées et opérationnelles
- ✓ IPs statiques configurées
- ✓ SSH accessible depuis le poste client
- ✓ Swap désactivée
- ✓ Outils de base installés

**Passez à : `02_installation_k3s.md`** pour installer K3S sur chaque VM.

---

## 📝 Notes et observations

Utilisez cette section pour noter vos observations :

```
VM kubes-01 : [notes]
VM kubes-02 : [notes]
VM kubes-03 : [notes]
Problèmes rencontrés : [problèmes]
Solutions appliquées : [solutions]
```

---

## 🔍 Dépannage courant

### Problème : SSH ne répond pas
```bash
# Vérifier SSH
sudo systemctl status ssh

# Relancer SSH
sudo systemctl restart ssh

# Vérifier les logs
sudo tail -f /var/log/auth.log
```

### Problème : IP non statique
```bash
# Vérifier la configuration
ip addr show
ip route show

# Relancer networking
sudo netplan apply
# ou
sudo systemctl restart networking
```

### Problème : Pas d'accès internet
```bash
ping 8.8.8.8
route -n
cat /etc/resolv.conf
```

---

**✅ Étape 1 complète ! Vous êtes prêt pour l'installation de K3S.**
