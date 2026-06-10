#!/bin/bash
# 02_install_k3s.sh
# Script d'installation K3S (Master sur kubes-01)

set -e

echo "=== Installation K3S Master ==="

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Vérifier les prérequis
echo "Vérification des prérequis..."
if free | grep -q "Swap" && [ $(free | grep Swap | awk '{print $2}') -ne 0 ]; then
    echo "ERREUR: Swap activé. Exécutez d'abord 01_setup_vms.sh"
    exit 1
fi

echo "✓ Prérequis OK"
echo ""

# Installer K3S
echo "Installation de K3S..."
curl -sfL https://get.k3s.io | sh -

# Attendre que K3S démarre
echo "Attente du démarrage de K3S (30s)..."
sleep 30

# Vérifier l'installation
echo ""
echo "Vérification de l'installation..."
if systemctl is-active --quiet k3s; then
    echo "✓ K3S démarré correctement"
else
    echo "✗ Erreur lors du démarrage de K3S"
    systemctl status k3s
    exit 1
fi

# Vérifier kubectl
echo ""
echo "Test de kubectl..."
if kubectl get nodes &> /dev/null; then
    echo "✓ kubectl fonctionne"
else
    echo "✗ kubectl ne répond pas"
    exit 1
fi

# Afficher le token pour les workers
echo ""
echo "=== IMPORTANT ==="
echo "Copier le token ci-dessous pour les workers:"
echo ""
cat /var/lib/rancher/k3s/server/node-token
echo ""
echo "Commande pour rejoindre (sur les workers):"
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$(hostname -I | awk '{print $1}'):6443 K3S_TOKEN=<TOKEN> sh -"
echo ""

# Afficher l'état du cluster
echo "État du cluster:"
kubectl get nodes

echo ""
echo "Installation Master terminée !"
