#!/bin/bash
# 01_setup_vms_fixed.sh
# Script de configuration des VMs avant K3S
set -e

echo "=== Configuration des VMs pour K3S ==="

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si root
if [[ $EUID -ne 0 ]]; then
    error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Variables
HOSTNAME_PREFIX="kubes-03"
DOMAIN="local"
NETWORK_PREFIX="192.168.136.186"

# ========== ÉTAPE 1 : Mise à jour système ==========
info "Étape 1 : Mise à jour du système..."
apt-get update
apt-get upgrade -y

# Installation des dépendances (SANS iptables-legacy)
info "Installation des dépendances..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    apparmor \
    ca-certificates \
    openssh-server \
    openssh-client \
    sudo \
    cgroup-tools

info "✓ Système mis à jour"

# ========== ÉTAPE 2 : Configurer iptables pour Trixie ==========
info "Étape 2 : Configuration d'iptables..."

# Utiliser les alternatives modernes au lieu de iptables-legacy
update-alternatives --install /usr/sbin/iptables iptables /usr/sbin/iptables-nft 100
update-alternatives --install /usr/sbin/ip6tables ip6tables /usr/sbin/ip6tables-nft 100
update-alternatives --install /usr/sbin/iptables-save iptables-save /usr/sbin/iptables-nft-save 100
update-alternatives --install /usr/sbin/iptables-restore iptables-restore /usr/sbin/iptables-nft-restore 100

# Vérifier
IPTABLES_VERSION=$(iptables --version)
info "✓ iptables configuré : $IPTABLES_VERSION"

# ========== ÉTAPE 3 : Désactiver le swap ==========
info "Étape 3 : Désactivation du swap..."
swapoff -a

# Commenter les lignes swap dans fstab (sans créer de sauvegarde si déjà modifié)
if grep -q "/ swap " /etc/fstab; then
    sed -i '/ swap / s/^/#/' /etc/fstab
fi

# Vérifier
SWAP_SIZE=$(free | grep Swap | awk '{print $2}')
if [ "$SWAP_SIZE" -eq 0 ]; then
    info "✓ Swap désactivé avec succès"
else
    warn "⚠ Swap : $SWAP_SIZE KB (devrait être 0)"
fi

# ========== ÉTAPE 4 : Configurer les modules kernel ==========
info "Étape 4 : Configuration des modules kernel..."

cat > /etc/modules-load.d/k3s.conf << 'EOF'
overlay
br_netfilter
EOF

# Charger les modules immédiatement
modprobe overlay 2>/dev/null || warn "Impossible de charger overlay (normal si déjà chargé)"
modprobe br_netfilter 2>/dev/null || warn "Impossible de charger br_netfilter (normal si déjà chargé)"

# Vérifier
if lsmod | grep -q "br_netfilter"; then
    info "✓ Modules kernel chargés"
else
    warn "⚠ Modules kernel : seront chargés au redémarrage"
fi

# ========== ÉTAPE 5 : Configurer sysctl ==========
info "Étape 5 : Configuration sysctl..."

cat > /etc/sysctl.d/99-k3s.conf << 'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
vm.overcommit_memory = 1
EOF

# Appliquer les paramètres
sysctl -p /etc/sysctl.d/99-k3s.conf > /dev/null 2>&1

# Vérifier
if sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null | grep -q "= 1"; then
    info "✓ sysctl configuré correctement"
else
    warn "⚠ Certains paramètres sysctl pourraient ne pas être appliqués"
fi

# ========== ÉTAPE 6 : Ouvrir les ports firewall ==========
info "Étape 6 : Configuration du firewall..."

# Vérifier si UFW est installé et activé
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    
    if [[ "$UFW_STATUS" == "Status: active" ]] || [[ "$UFW_STATUS" == "Status: inactive" ]]; then
        info "UFW détecté, configuration des règles..."
        
        # SSH
        ufw allow 22/tcp > /dev/null 2>&1 || true
        
        # Kubernetes API (Master)
        ufw allow 6443/tcp > /dev/null 2>&1 || true
        
        # Kubelet
        ufw allow 10250/tcp > /dev/null 2>&1 || true
        
        # Scheduler (optionnel, master)
        ufw allow 10251/tcp > /dev/null 2>&1 || true
        
        # Controller Manager (optionnel, master)
        ufw allow 10252/tcp > /dev/null 2>&1 || true
        
        # Kubelet read-only
        ufw allow 10255/tcp > /dev/null 2>&1 || true
        
        # NodePort services (30000-32767)
        ufw allow 30000:32767/tcp > /dev/null 2>&1 || true
        
        # Enable UFW (si pas déjà actif)
        if [[ "$UFW_STATUS" == "Status: inactive" ]]; then
            echo "y" | ufw enable > /dev/null 2>&1 || true
        fi
        
        info "✓ Firewall configuré"
    else
        warn "UFW non activé, configuration manuelle recommandée"
    fi
else
    warn "UFW non installé"
    warn "Configurez manuellement les ports :"
    echo "  SSH: 22/tcp"
    echo "  Kubernetes API: 6443/tcp"
    echo "  Kubelet: 10250/tcp"
    echo "  NodePort: 30000:32767/tcp"
fi

# ========== ÉTAPE 7 : Configuration réseau ==========
info "Étape 7 : Vérification de la configuration réseau..."

CURRENT_IP=$(hostname -I | awk '{print $1}')
CURRENT_HOSTNAME=$(hostname)

info "Hostname: $CURRENT_HOSTNAME"
info "IP: $CURRENT_IP"

# Vérifier la connectivité
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    info "✓ Connectivité réseau : OK"
else
    warn "⚠ Pas de connectivité externe (peut être normal)"
fi

# ========== ÉTAPE 8 : Afficher le résumé ==========
info ""
info "========== RÉSUMÉ DE CONFIGURATION =========="
echo ""
echo "Hostname: $(hostname)"
echo "IP: $CURRENT_IP"
echo "Swap: $(free | grep Swap | awk '{printf "%d KB", $2}')"
echo "Iptables: $(iptables --version | cut -d' ' -f1-2)"
echo ""
echo "Modules kernel chargés:"
lsmod | grep -E "br_netfilter|overlay" | awk '{print "  - " $1}' || echo "  (À charger au redémarrage)"
echo ""
echo "Paramètres sysctl :"
echo "  net.bridge.bridge-nf-call-iptables = $(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo '?')"
echo "  net.ipv4.ip_forward = $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo '?')"
echo ""
echo "=========================================="
echo ""

# ========== ÉTAPE 9 : Afficher les prochaines étapes ==========
info "Configuration terminée !"
echo ""
echo "📝 Prochaines étapes :"
echo "  1. Redémarrer la VM (recommandé) : sudo reboot"
echo "  2. Installer K3S : sudo bash ./install_k3s_fixed.sh master (ou worker)"
echo ""
echo "✅ Votre VM est prête pour K3S !"
echo ""

exit 0