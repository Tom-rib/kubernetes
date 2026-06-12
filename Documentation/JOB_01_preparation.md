# JOB 01 — Préparation & Configuration Debian Trixie

**Objectif** : Préparer 3 VMs Debian Trixie pour installer K3S. Configurer le réseau, le firewall (nftables), les kernel modules et les paramètres systèmes.

**Durée estimée** : 30 minutes  
**Ressources** : 3 VMs avec 2 CPU min, 2 Go RAM min, 20 Go disque

---

## 📊 Schéma du Réseau

```
┌─────────────────────────────────────────────┐
│           Réseau Local                      │
│         (192.168.1.0/24)                   │
├─────────────────────────────────────────────┤
│                                             │
│  kubes-01.local (192.168.1.11)  [Master]  │
│  └─ K3S Server (Maître du cluster)         │
│                                             │
│  kubes-02.local (192.168.1.12)  [Worker1] │
│  └─ K3S Agent                              │
│                                             │
│  kubes-03.local (192.168.1.13)  [Worker2] │
│  └─ K3S Agent                              │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎯 Checklist de Préparation

### 1. Configuration des VMs

- [ ] 3 VMs Debian Trixie déployées
- [ ] Hostnames configurés : `kubes-01`, `kubes-02`, `kubes-03`
- [ ] Adresses IP statiques (192.168.1.11, 12, 13)
- [ ] Accès SSH sans mot de passe (optionnel mais recommandé)

### 2. Prérequis Système

- [ ] Mises à jour système (`apt update && apt upgrade`)
- [ ] Kernel modules chargés : `br_netfilter`, `overlay`
- [ ] Sysctl configurés : IP forwarding, bridge netfilter
- [ ] nftables configuré et persistant
- [ ] Swap désactivé

### 3. Vérification Réseau

- [ ] Ping entre les 3 VMs OK
- [ ] DNS résolvant les noms `.local`
- [ ] Pas de firewall bloquant les ports K3S (6443, 10250)

---

## ⚙️ Configuration Détaillée

### Étape 1 : Mise à Jour du Système

```bash
# Sur chaque VM
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  curl wget git vim htop nftables sysctl \
  ca-certificates apt-transport-https
```

**Vérification** :
```bash
uname -r          # Version du kernel
cat /etc/os-release | grep VERSION
```

### Étape 2 : Configuration des Hostnames

```bash
# Sur kubes-01
sudo hostnamectl set-hostname kubes-01.local

# Sur kubes-02
sudo hostnamectl set-hostname kubes-02.local

# Sur kubes-03
sudo hostnamectl set-hostname kubes-03.local
```

Éditer `/etc/hosts` sur chaque VM :

```bash
sudo nano /etc/hosts
```

Ajouter les trois lignes :

```
192.168.1.11  kubes-01.local  kubes-01
192.168.1.12  kubes-02.local  kubes-02
192.168.1.13  kubes-03.local  kubes-03
```

**Vérification** :
```bash
hostname
cat /etc/hosts
ping kubes-01.local
```

### Étape 3 : Configuration IP Statique (Debian Trixie)

Éditer `/etc/network/interfaces` ou utiliser netplan selon votre setup.

**Avec netplan** (moderne) :

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

**Exemple pour kubes-01** :

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.11/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

Appliquer :

```bash
sudo netplan apply
ip a  # Vérifier l'adresse
```

### Étape 4 : Charger les Kernel Modules

**Vérifier si déjà chargés** :

```bash
lsmod | grep -E 'br_netfilter|overlay'
```

**Charger les modules** :

```bash
sudo modprobe br_netfilter
sudo modprobe overlay
```

**Persister au démarrage** :

```bash
echo "br_netfilter" | sudo tee /etc/modules-load.d/k3s.conf
echo "overlay" | sudo tee -a /etc/modules-load.d/k3s.conf

# Vérifier
cat /etc/modules-load.d/k3s.conf
```

### Étape 5 : Configuration Sysctl pour K3S

```bash
sudo nano /etc/sysctl.d/99-k3s.conf
```

Ajouter :

```ini
# IP Forwarding (essentiel pour le routing des pods)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Bridge netfilter (permet à iptables/nftables de voir le trafic des bridges)
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# Optimisations réseau K3S
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0

# Augmenter les connexions
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
```

**Appliquer les changements** :

```bash
sudo sysctl -p /etc/sysctl.d/99-k3s.conf
```

**Vérifier** :

```bash
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
```

### Étape 6 : Configuration Firewall (nftables - Debian Trixie)

⚠️ **Important** : Debian Trixie n'a pas `iptables-legacy`. Nous utilisons `nftables` directement.

**Éditer la configuration** :

```bash
sudo nano /etc/nftables.conf
```

**Remplacer le contenu par** :

```nftables
#!/usr/bin/nft -f

flush ruleset

# Définir les tables et chaînes
table inet filter {
    chain input {
        type filter hook input priority filter; policy accept;
        
        # Loopback
        iifname lo accept
        
        # Established connections
        ct state established,related accept
        
        # ICMP (ping)
        ip protocol icmp accept
        ipv6 nexthdr icmpv6 accept
        
        # SSH (22)
        tcp dport 22 accept
        
        # K3S API Server (6443)
        tcp dport 6443 accept
        
        # Kubelet (10250)
        tcp dport 10250 accept
        
        # K3S Service NodePort range (30000-32767)
        tcp dport 30000-32767 accept
        udp dport 30000-32767 accept
        
        # Flannel VXLAN (8472)
        udp dport 8472 accept
        
        # CoreDNS (53)
        tcp dport 53 accept
        udp dport 53 accept
        
        # Drop tout le reste
        reject with icmp type port-unreachable
    }
    
    chain forward {
        type filter hook forward priority filter; policy accept;
    }
    
    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

**Activer et démarrer nftables** :

```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
```

**Vérifier les règles** :

```bash
sudo nft list ruleset
```

**Test de connectivité** :

```bash
sudo nft list ruleset | grep dport
ping 8.8.8.8              # Internet OK?
ssh other-vm              # SSH OK?
```

### Étape 7 : Désactiver le Swap

K3S/Kubernetes fonctionne mieux sans swap (le scheduler ne peut pas bien estimer les ressources).

```bash
# Vérifier le swap actif
free -h | grep Swap

# Désactiver temporairement
sudo swapoff -a

# Persister au démarrage
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Vérifier
free -h
```

---

## 🔍 Vérification Complète (JOB 01)

```bash
# Sur chaque VM, exécuter :

echo "=== HOSTNAME ==="
hostname

echo "=== IP ==="
ip a | grep 192.168

echo "=== PING INTER-NODES ==="
ping -c 2 kubes-01.local
ping -c 2 kubes-02.local
ping -c 2 kubes-03.local

echo "=== KERNEL MODULES ==="
lsmod | grep -E 'br_netfilter|overlay'

echo "=== SYSCTL IP_FORWARD ==="
sysctl net.ipv4.ip_forward

echo "=== NFTABLES RULES ==="
sudo nft list ruleset | grep -E 'dport|chain'

echo "=== SWAP ==="
free -h | grep Swap

echo "=== PORTS K3S ==="
sudo ss -tulpn | grep -E '22|6443|10250'
```

**Résultat attendu** :
- ✅ Hostnames OK
- ✅ Adresses IP statiques assignées
- ✅ Ping inter-VMs OK
- ✅ `br_netfilter` et `overlay` en `lsmod`
- ✅ `net.ipv4.ip_forward = 1`
- ✅ nftables actif et règles OK
- ✅ Swap = 0 (désactivé)

---

## 📝 Dépannage JOB 01

| Problème | Solution |
|----------|----------|
| Hostnames ne pingent pas | Vérifier `/etc/hosts` et appliquer netplan |
| `br_netfilter` non chargé | `sudo modprobe br_netfilter` + `/etc/modules-load.d/` |
| nftables bloque SSH | Ajouter `tcp dport 22 accept` |
| `sysctl` ne change pas | Éditer `/etc/sysctl.d/99-k3s.conf` et `sysctl -p` |
| Swap toujours actif | Vérifier `/etc/fstab`, ajouter `#` en début de ligne swap |

---

## ✅ Prêt pour JOB 02 ?

Une fois le JOB 01 validé :

```bash
# Depuis une VM, vérifier:
ping kubes-01.local && ping kubes-02.local && ping kubes-03.local
# Doit retourner : 3 succès
```

→ **Suivant** : [JOB 02 — Installation K3S](./JOB_02_installation.md)

---

**Ressources**
- Debian Trixie Networking : https://wiki.debian.org/DebianTrixie
- nftables wiki : https://wiki.nftables.org/
- K3S Requirements : https://docs.k3s.io/installation/requirements

**Notes de l'étudiant** :
```
[À remplir lors de la réalisation]
- Adresses IP attribuées : kubes-01: ___ kubes-02: ___ kubes-03: ___
- Problèmes rencontrés : ___
- Temps d'exécution : ___
```
