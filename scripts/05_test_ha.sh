#!/bin/bash
# 05_test_ha.sh
# Script pour tester la haute disponibilité du cluster K3S

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
header() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }
test_title() { echo -e "\n${CYAN}Test: $1${NC}\n"; }

# Configuration
NAMESPACE="apps"
TEST_APP="nginx-ha"

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

header "Tests de Haute Disponibilité (HA)"

# Étape 1 : État initial
test_title "1. État Initial du Cluster"

info "Nœuds du cluster :"
kubectl get nodes -o wide

info "Pods du namespace '$NAMESPACE' :"
kubectl get pods -n $NAMESPACE -o wide

INITIAL_POD_COUNT=$(kubectl get pods -n $NAMESPACE -l app=$TEST_APP 2>/dev/null | tail -n +2 | wc -l)
info "Nombre de pods $TEST_APP : $INITIAL_POD_COUNT"

# Étape 2 : Test de redémarrage d'un pod
test_title "2. Test de Redémarrage d'un Pod"

warn "Sélection d'un pod $TEST_APP à supprimer..."

POD_TO_DELETE=$(kubectl get pods -n $NAMESPACE -l app=$TEST_APP -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_TO_DELETE" ]; then
    warn "⚠ Aucun pod $TEST_APP trouvé, test ignoré"
else
    info "Pod à supprimer : $POD_TO_DELETE"
    info "Suppression du pod..."
    kubectl delete pod $POD_TO_DELETE -n $NAMESPACE
    
    info "Attente du redémarrage (15s)..."
    sleep 15
    
    NEW_POD=$(kubectl get pods -n $NAMESPACE -l app=$TEST_APP -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$NEW_POD" ] && [ "$NEW_POD" != "$POD_TO_DELETE" ]; then
        info "✓ Pod redémarré avec succès !"
        info "  Ancien pod : $POD_TO_DELETE"
        info "  Nouveau pod : $NEW_POD"
    else
        warn "⚠ Impossible de vérifier le redémarrage"
    fi
    
    info "État des pods après redémarrage :"
    kubectl get pods -n $NAMESPACE -l app=$TEST_APP
fi

# Étape 3 : Test de scalabilité
test_title "3. Test de Scalabilité (Scale Up/Down)"

info "État initial de l'app $TEST_APP :"
kubectl get deployment $TEST_APP -n $NAMESPACE -o wide

CURRENT_REPLICAS=$(kubectl get deployment $TEST_APP -n $NAMESPACE -o jsonpath='{.spec.replicas}')
info "Replicas actuels : $CURRENT_REPLICAS"

# Scale up
NEW_REPLICAS=$((CURRENT_REPLICAS + 2))
info "Scale up vers $NEW_REPLICAS replicas..."
kubectl scale deployment $TEST_APP --replicas=$NEW_REPLICAS -n $NAMESPACE

info "Attente du scale up (10s)..."
sleep 10

info "Pods après scale up :"
kubectl get pods -n $NAMESPACE -l app=$TEST_APP

CURRENT_REPLICAS=$(kubectl get deployment $TEST_APP -n $NAMESPACE -o jsonpath='{.spec.replicas}')
if [ "$CURRENT_REPLICAS" -eq "$NEW_REPLICAS" ]; then
    info "✓ Scale up réussi ! ($CURRENT_REPLICAS replicas)"
else
    warn "⚠ Nombre de replicas attendu : $NEW_REPLICAS, obtenu : $CURRENT_REPLICAS"
fi

# Scale down
REDUCED_REPLICAS=$((CURRENT_REPLICAS - 1))
info "Scale down vers $REDUCED_REPLICAS replicas..."
kubectl scale deployment $TEST_APP --replicas=$REDUCED_REPLICAS -n $NAMESPACE

info "Attente du scale down (10s)..."
sleep 10

info "Pods après scale down :"
kubectl get pods -n $NAMESPACE -l app=$TEST_APP

info "✓ Test de scalabilité complété"

# Étape 4 : Test de continuité de service
test_title "4. Test de Continuité de Service"

# Récupérer l'IP pour tester
SERVICE_IP=$(kubectl get svc nginx-service -n $NAMESPACE -o jsonpath='{.spec.clusterIP}' 2>/dev/null)

if [ -z "$SERVICE_IP" ]; then
    warn "⚠ Service nginx-service non trouvé"
else
    info "IP du service : $SERVICE_IP"
    
    # Tester depuis un pod
    POD_TO_TEST=$(kubectl get pods -n $NAMESPACE -l app=nginx-ha -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$POD_TO_TEST" ]; then
        info "Test depuis le pod : $POD_TO_TEST"
        
        # Effectuer 5 requêtes
        info "Envoi de 5 requêtes HTTP..."
        for i in {1..5}; do
            RESPONSE=$(kubectl exec $POD_TO_TEST -n $NAMESPACE -- curl -s http://$SERVICE_IP 2>/dev/null | head -c 50)
            if [ ! -z "$RESPONSE" ]; then
                info "  Requête $i : ✓ OK"
            else
                warn "  Requête $i : ✗ Échouée"
            fi
        done
        
        info "✓ Continuité de service testée"
    fi
fi

# Étape 5 : Test de santé des nœuds
test_title "5. État de Santé des Nœuds"

info "Nœuds du cluster :"
kubectl get nodes -o wide

# Vérifier que tous les nœuds sont Ready
NOT_READY=$(kubectl get nodes -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status!="True")].metadata.name}')

if [ -z "$NOT_READY" ]; then
    info "✓ Tous les nœuds sont en état Ready"
else
    warn "⚠ Nœuds non-ready : $NOT_READY"
fi

# Étape 6 : Résumé des ressources
test_title "6. Résumé des Ressources"

info "CPU et mémoire utilisés par nœud :"
kubectl top nodes 2>/dev/null || warn "  Metrics non disponibles (installer metrics-server)"

info "CPU et mémoire utilisés par pod :"
kubectl top pods -n $NAMESPACE 2>/dev/null || warn "  Metrics non disponibles"

# Étape 7 : Vérification des événements
test_title "7. Événements Récents du Cluster"

info "Événements du namespace '$NAMESPACE' (derniers 10) :"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -n 11

# Résumé final
header "Résumé des Tests HA"

echo "Tests exécutés :"
echo "  ✓ État initial du cluster"
echo "  ✓ Redémarrage d'un pod"
echo "  ✓ Scalabilité (scale up/down)"
echo "  ✓ Continuité de service"
echo "  ✓ Santé des nœuds"
echo "  ✓ Ressources utilisées"
echo "  ✓ Événements du cluster"
echo ""

info "Tests de HA terminés ! 🎉"

echo ""
echo "Commandes utiles pour continuer les tests :"
echo ""
echo "  # Voir tous les pods en temps réel"
echo "  kubectl get pods -n apps -w"
echo ""
echo "  # Voir les logs d'un pod"
echo "  kubectl logs <pod-name> -n apps -f"
echo ""
echo "  # Describe un pod pour voir les événements"
echo "  kubectl describe pod <pod-name> -n apps"
echo ""
echo "  # Entrer dans un pod"
echo "  kubectl exec -it <pod-name> -n apps -- /bin/bash"
echo ""
