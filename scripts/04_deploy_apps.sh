#!/bin/bash
# 04_deploy_apps.sh
# Script pour déployer les applications (nginx, apache, mariadb) sur le cluster

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

# Vérifier kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl n'est pas installé"
    exit 1
fi

# Vérifier la connectivité du cluster
if ! kubectl cluster-info &> /dev/null; then
    error "Impossible de se connecter au cluster K3S"
    exit 1
fi

header "Déploiement des Applications sur K3S"

# Configuration
STORAGE_PATHS=("/mnt/storage/nginx" "/mnt/storage/mariadb")
NAMESPACE="apps"

# Étape 1 : Créer les répertoires de stockage sur chaque nœud
header "Création des répertoires de stockage"

NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

for NODE in $NODES; do
    info "Configuration du nœud : $NODE"
    
    # SSH dans chaque nœud et créer les répertoires
    for PATH in "${STORAGE_PATHS[@]}"; do
        ssh root@$NODE "mkdir -p $PATH && chmod 777 $PATH" 2>/dev/null || \
        warn "  Impossible d'accéder à $NODE (assurez-vous SSH est configuré)"
    done
    
    info "✓ Répertoires créés sur $NODE"
done

# Étape 2 : Créer le namespace
header "Création du namespace"

info "Création du namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE 2>/dev/null || info "  Namespace '$NAMESPACE' existe déjà"

# Étape 3 : Déployer les manifests
header "Déploiement des applications"

# Vérifier que les fichiers manifests existent
MANIFEST_DIR="./manifests"
if [ ! -d "$MANIFEST_DIR" ]; then
    error "Dossier manifests/$MANIFEST_DIR non trouvé"
    error "Assurez-vous d'être dans le répertoire du projet"
    exit 1
fi

# Déployer nginx
info "Déploiement de Nginx..."
if kubectl apply -f $MANIFEST_DIR/01-nginx-deployment.yaml 2>/dev/null; then
    info "✓ Nginx déployé"
else
    warn "⚠ Erreur lors du déploiement de Nginx"
fi

# Déployer apache
info "Déploiement d'Apache..."
if kubectl apply -f $MANIFEST_DIR/03-apache-deployment.yaml 2>/dev/null; then
    info "✓ Apache déployé"
else
    warn "⚠ Erreur lors du déploiement d'Apache"
fi

# Déployer mariadb
info "Déploiement de MariaDB..."
if kubectl apply -f $MANIFEST_DIR/02-mariadb-deployment.yaml 2>/dev/null; then
    info "✓ MariaDB déployé"
else
    warn "⚠ Erreur lors du déploiement de MariaDB"
fi

# Alternative : déployer tout d'un coup
# info "Déploiement de toutes les applications..."
# kubectl apply -f $MANIFEST_DIR/all-in-one.yaml

# Étape 4 : Attendre que les pods démarrent
header "Attente du démarrage des pods"

info "Attente de 30 secondes pour que les pods démarrent..."
sleep 30

# Étape 5 : Vérifier le statut
header "Vérification du déploiement"

info "Pods dans le namespace '$NAMESPACE' :"
kubectl get pods -n $NAMESPACE -o wide

info "Services dans le namespace '$NAMESPACE' :"
kubectl get svc -n $NAMESPACE

info "PersistentVolumeClaims :"
kubectl get pvc -n $NAMESPACE

# Étape 6 : Afficher les URLs d'accès
header "URLs d'accès aux applications"

# Récupérer les adresses IP des nœuds
MASTER_IP=$(kubectl get nodes -o wide | tail -n +2 | head -1 | awk '{print $6}')

echo "Applications disponibles à :"
echo ""
echo "  Nginx  : http://${MASTER_IP}:80"
echo "           (ou utilisez: kubectl port-forward svc/nginx-service 8080:80 -n apps)"
echo ""
echo "  Apache : http://${MASTER_IP}:80"
echo "           (ou utilisez: kubectl port-forward svc/apache-service 8081:80 -n apps)"
echo ""
echo "  MariaDB: ${MASTER_IP}:3306"
echo "           (ou utilisez: kubectl port-forward svc/mariadb-service 3306:3306 -n apps)"
echo ""

# Résumé
header "Déploiement terminé"

echo "Prochaines étapes :"
echo ""
echo "1. Vérifier les logs d'un pod :"
echo "   kubectl logs <pod-name> -n apps"
echo ""
echo "2. Entrer dans un pod :"
echo "   kubectl exec -it <pod-name> -n apps -- /bin/bash"
echo ""
echo "3. Tester la connectivité :"
echo "   kubectl exec <nginx-pod> -n apps -- curl http://localhost"
echo ""
echo "4. Voir les événements :"
echo "   kubectl get events -n apps"
echo ""
echo "5. Tester MariaDB :"
echo "   kubectl exec <mariadb-pod> -n apps -- mysql -u root -proot123 -e 'SHOW DATABASES;'"
echo ""

info "Applications déployées avec succès ! ✓"
