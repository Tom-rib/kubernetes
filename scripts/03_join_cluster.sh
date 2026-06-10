#!/bin/bash
# 03_join_cluster.sh
# Script pour faire rejoindre les workers au cluster K3S master

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
header() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Configuration
MASTER_IP="${1:-192.168.1.101}"
WORKER_IPS=("192.168.1.102" "192.168.1.103")

header "Rejoindre les workers au cluster K3S"

# Étape 1 : Récupérer le token depuis le master
echo "Connexion au master pour récupérer le token..."

TOKEN=$(sshpass -p "root" ssh -o StrictHostKeyChecking=no root@${MASTER_IP} \
    'cat /var/lib/rancher/k3s/server/node-token' 2>/dev/null)

if [ -z "$TOKEN" ]; then
    error "Impossible de récupérer le token du master"
    error "Assurez-vous que :"
    error "1. Le master K3S est en cours d'exécution"
    error "2. L'IP ${MASTER_IP} est correcte"
    error "3. SSH (root) est accessible"
    exit 1
fi

info "✓ Token récupéré avec succès"
echo "Token: ${TOKEN:0:20}..."

# Étape 2 : Faire rejoindre chaque worker
header "Ajout des workers au cluster"

for WORKER_IP in "${WORKER_IPS[@]}"; do
    info "Ajout du worker : ${WORKER_IP}"
    
    # Installer K3S en mode agent/worker
    sshpass -p "root" ssh -o StrictHostKeyChecking=no root@${WORKER_IP} \
        "curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${TOKEN} sh -" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        info "✓ Worker ${WORKER_IP} rejoint avec succès"
    else
        error "✗ Erreur lors du join du worker ${WORKER_IP}"
    fi
    
    sleep 5
done

# Étape 3 : Vérifier les nœuds
header "Vérification du cluster"

info "Attente du démarrage des workers (30s)..."
sleep 30

info "État des nœuds :"
kubectl get nodes

# Vérifier que tous les nœuds sont présents
NODE_COUNT=$(kubectl get nodes | tail -n +2 | wc -l)

if [ $NODE_COUNT -eq 3 ]; then
    info "✓ Tous les nœuds sont présents (3/3)"
else
    warn "⚠ Seulement $NODE_COUNT nœuds détectés (attendu 3)"
fi

# Étape 4 : Vérifier que les pods système démarrent
header "Vérification des pods système"

info "Pods kube-system :"
kubectl get pods -n kube-system

info "Pods kube-node-lease :"
kubectl get pods -n kube-node-lease

# Résumé
header "Configuration du cluster terminée"

echo "Résumé :"
echo "  Master : ${MASTER_IP}"
echo "  Workers : ${WORKER_IPS[@]}"
echo "  Total de nœuds : $NODE_COUNT"
echo ""
echo "Prochaines étapes :"
echo "  1. Créer le namespace 'apps'"
echo "  2. Déployer les applications"
echo "  3. Vérifier les services"
echo ""
echo "Pour créer les répertoires de storage sur les workers :"
echo "  bash 04_deploy_apps.sh"
echo ""

info "Cluster K3S prêt ! 🚀"
