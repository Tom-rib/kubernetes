# 05 - Annexes : Commandes, Dépannage et Mémos

## 📚 Table des matières
1. [Mémo kubectl](#mémo-kubectl)
2. [Mémo Kubernetes](#mémo-kubernetes)
3. [Mémo Helm](#mémo-helm)
4. [Dépannage courant](#dépannage-courant)
5. [Debugging avancé](#debugging-avancé)
6. [Performance et monitoring](#performance-et-monitoring)

---

## 🎯 Mémo kubectl

### Installation et configuration

```bash
# Installer kubectl
sudo apt install -y kubectl

# Ou avec Kubernetes
curl -O https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Vérifier
kubectl version
kubectl cluster-info
kubectl config current-context
```

### Contextes et clusters

```bash
# Voir les contextes
kubectl config get-contexts
kubectl config current-context

# Changer de contexte
kubectl config use-context my-context

# Voir le kubeconfig
cat ~/.kube/config

# Merger des kubeconfigs
KUBECONFIG=~/.kube/config:~/.kube/other-config kubectl config view
```

### Navigation et exploration

```bash
# Clusters
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node kubes-01

# Namespaces
kubectl get namespaces
kubectl create namespace my-ns
kubectl delete namespace my-ns
kubectl config set-context --current --namespace=my-ns

# Ressources
kubectl api-resources
kubectl api-versions
kubectl explain pods    # Doc d'une ressource
```

### Déploiement

```bash
# Appliquer des manifests
kubectl apply -f deployment.yaml
kubectl apply -f *.yaml
kubectl apply -R -f ./manifests/

# Créer rapidement
kubectl create deployment my-app --image=nginx:latest
kubectl create service nodeport web --tcp=8080:80

# Voir les deployments
kubectl get deployments
kubectl get deployment my-app -o yaml
```

### Pods et exécution

```bash
# Voir les pods
kubectl get pods
kubectl get pods -n kube-system
kubectl get pods -A (--all-namespaces)
kubectl get pods -o wide
kubectl get pods -l app=nginx

# Détails
kubectl describe pod my-pod
kubectl get pod my-pod -o yaml

# Logs
kubectl logs my-pod
kubectl logs -f deployment/my-app
kubectl logs --all-containers=true my-pod
kubectl logs my-pod --previous

# Exécuter
kubectl exec -it my-pod -- /bin/bash
kubectl exec my-pod -- ls -la
kubectl attach my-pod -i -t
```

### Services et networking

```bash
# Voir les services
kubectl get services
kubectl get svc
kubectl describe svc my-service

# Port forwarding
kubectl port-forward pod/my-pod 8080:80
kubectl port-forward svc/my-service 8080:80

# Tester la connectivité
kubectl exec my-pod -- curl http://my-service:80
```

### Modifications et mises à jour

```bash
# Éditer une ressource
kubectl edit deployment my-app
kubectl edit pod my-pod

# Patcher
kubectl patch deployment my-app -p '{"spec":{"replicas":5}}'
kubectl patch service my-svc -p '{"spec":{"type":"LoadBalancer"}}'

# Set
kubectl set image deployment/my-app app=nginx:1.25
kubectl set env deployment/my-app ENV_VAR=value

# Scale
kubectl scale deployment my-app --replicas=5
```

### Suppression

```bash
# Supprimer une ressource
kubectl delete pod my-pod
kubectl delete deployment my-app
kubectl delete -f deployment.yaml

# Suppression immédiate
kubectl delete pod my-pod --grace-period=0 --force
```

### Troubleshooting

```bash
# État général
kubectl get events
kubectl get events -A
kubectl top nodes
kubectl top pods

# Diagnostics
kubectl describe nodes
kubectl describe pods
kubectl get pod my-pod -o yaml | grep -i status

# Logs système
kubectl logs -n kube-system [POD_NAME]
```

---

## 📖 Mémo Kubernetes

### Ressources principales

```yaml
# Pod (unité de base)
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx:latest

# Deployment (avec replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: myapp:latest

# Service (expose les pods)
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080

# ConfigMap (configuration)
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  config.yml: |
    server:
      port: 8080

# Secret (données sensibles)
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  password: supersecret

# PersistentVolume (stockage)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data

# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
```

### Labels et sélecteurs

```bash
# Ajouter un label
kubectl label pod my-pod app=nginx

# Filtrer par label
kubectl get pods -l app=nginx
kubectl get pods -l env=production,tier=frontend

# Supprimer un label
kubectl label pod my-pod app-
```

### Probes (santé des pods)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    
    # Liveness probe (redémarrer si failed)
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
    
    # Readiness probe (trafic si ready)
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    
    # Startup probe (appli lent démarrage)
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

---

## 🎯 Mémo Helm

### Installation et setup

```bash
# Installer Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Vérifier
helm version
helm list

# Ajouter un repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx
```

### Charts

```bash
# Créer un chart
helm create my-chart

# Voir la structure
tree my-chart/

# Valider
helm lint my-chart

# Voir les templates générés
helm template my-release my-chart
helm template my-release my-chart --values values.yaml
```

### Installation et management

```bash
# Installer une release
helm install my-release my-chart

# Avec valeurs personnalisées
helm install my-release my-chart \
  --values custom-values.yaml \
  --set replicaCount=5

# Voir les releases
helm list
helm list -a (--all)
helm list -n my-namespace

# Statut
helm status my-release
helm get values my-release
helm get notes my-release
helm get manifest my-release
```

### Mises à jour et rollback

```bash
# Mettre à jour
helm upgrade my-release my-chart
helm upgrade my-release my-chart --values new-values.yaml

# Historique
helm history my-release

# Rollback
helm rollback my-release 1
helm rollback my-release 2

# Supprimer
helm uninstall my-release
helm uninstall my-release --keep-history
```

---

## 🐛 Dépannage courant

### Problème : Pod reste en Pending

```bash
# Vérifier l'événement
kubectl describe pod my-pod
# Regarder la section "Events"

# Causes possibles :
# - Pas assez de ressources (CPU/RAM)
# - PVC non liée
# - Image non trouvée
# - Pas de nœud compatible

# Solutions :
kubectl get nodes      # Voir l'espace disponible
kubectl top nodes      # Voir l'utilisation
kubectl scale deployment my-app --replicas=1  # Réduire
```

### Problème : Pod en CrashLoopBackOff

```bash
# Voir les logs
kubectl logs my-pod
kubectl logs my-pod --previous

# Vérifier la configuration
kubectl describe pod my-pod

# Problèmes courants :
# - Application ne démarre pas
# - Fichiers de config manquants
# - Permissions insuffisantes
# - Ports déjà occupés
```

### Problème : Pod ne se connecte pas au service

```bash
# Tester la DNS
kubectl exec my-pod -- nslookup my-service
kubectl exec my-pod -- nslookup my-service.default.svc.cluster.local

# Tester la connectivité
kubectl exec my-pod -- curl http://my-service

# Vérifier le service
kubectl get svc
kubectl describe svc my-service

# Vérifier les endpoints
kubectl get endpoints my-service
```

### Problème : Image ne se charge pas

```bash
# Vérifier l'image existe
docker pull nginx:latest  # Tester localement

# Voir les événements
kubectl describe pod my-pod

# Vérifier le registre
kubectl get secret -n default

# Ajouter les credentials du registre
kubectl create secret docker-registry my-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

### Problème : Pas d'accès au stockage persistant

```bash
# Vérifier les PV/PVC
kubectl get pv
kubectl get pvc
kubectl describe pvc my-pvc

# Vérifier les montages
kubectl exec my-pod -- mount | grep -i storage

# Voir l'espace disque
kubectl exec my-pod -- df -h
```

### Problème : Secret/ConfigMap non mis à jour

```bash
# Les pods ne reloadent pas automatiquement !
# Solution 1 : Redéployer les pods
kubectl rollout restart deployment/my-app

# Solution 2 : Utiliser une image avec watch
# (l'app relit les fichiers)

# Vérifier le secret/configmap
kubectl get secret my-secret -o yaml
kubectl get configmap my-config -o yaml
```

---

## 🔧 Debugging avancé

### Traçage des requêtes API

```bash
# Mode verbose
kubectl get pods -v 9

# Voir les appels API
kubectl get pods -v 8 2>&1 | grep -i "GET"

# Audit des événements
kubectl get events -A --sort-by='.lastTimestamp'
```

### Inspection approfondie

```bash
# État détaillé d'un pod
kubectl get pod my-pod -o json | jq '.status'

# Voir tous les labels
kubectl get pod my-pod --show-labels

# Voir les annotations
kubectl get pod my-pod -o jsonpath='{.metadata.annotations}' | jq .

# Voir les variables d'environnement
kubectl exec my-pod -- env
```

### Network troubleshooting

```bash
# Faire un ping entre pods
kubectl exec my-pod -- ping -c 2 other-pod

# Tester DNS
kubectl exec my-pod -- nslookup kubernetes.default

# Lancer un pod de debug
kubectl run -it debug --image=busybox -- sh
# Ou
kubectl debug -it pod/my-pod --image=busybox
```

### Accès aux fichiers

```bash
# Copier un fichier depuis le pod
kubectl cp default/my-pod:/var/log/app.log ./app.log

# Copier vers le pod
kubectl cp ./config.yml default/my-pod:/etc/app/config.yml

# Voir le filesystem
kubectl exec my-pod -- ls -la /
kubectl exec my-pod -- find / -name "config.*"
```

---

## 📊 Performance et monitoring

### Ressources utilisées

```bash
# Usage des nœuds
kubectl top nodes
kubectl top nodes -l kubernetes.io/hostname=kubes-01

# Usage des pods
kubectl top pods
kubectl top pods -n kube-system
kubectl top pods -A

# Voir les limits et requests
kubectl describe nodes
kubectl describe pod my-pod | grep -A 5 "Requests\|Limits"
```

### Monitoring simple

```bash
# Watch les pods
kubectl get pods --watch

# Watch les events
kubectl get events -A --watch

# Watch les métriques
watch kubectl top nodes
watch kubectl top pods
```

### Logs en temps réel

```bash
# Tous les logs
kubectl logs deployment/my-app --all-containers=true -f

# Plusieurs pods
kubectl logs -l app=nginx -f

# Pour un namespace
kubectl logs -n kube-system -l component=kubelet -f
```

---

## 📋 Checklists rapides

### Checklist : Pod santé

```bash
[ ] kubectl get pods                    # Status Running
[ ] kubectl describe pod my-pod         # No events errors
[ ] kubectl logs my-pod                 # No errors in logs
[ ] kubectl exec my-pod -- curl localhost  # App répond
[ ] kubectl top pod my-pod              # Ressources OK
```

### Checklist : Deployment santé

```bash
[ ] kubectl get deployments             # READY = DESIRED
[ ] kubectl rollout status deployment/my-app
[ ] kubectl get rs                      # Proper number of replicas
[ ] kubectl get pods -l app=my-app      # All running
[ ] kubectl get svc my-service          # Has endpoints
[ ] curl http://my-service              # Service répond
```

### Checklist : Cluster santé

```bash
[ ] kubectl get nodes                   # All Ready
[ ] kubectl get pods -n kube-system     # All Running
[ ] kubectl api-resources               # API responsive
[ ] kubectl get events -A               # No alarming events
[ ] kubectl top nodes                   # Resources OK
```

---

## 🔗 Fichiers de configuration utiles

### kubeconfig pour accès distant

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: [cert]
    server: https://kubes-01.local:6443
  name: k3s-cluster
contexts:
- context:
    cluster: k3s-cluster
    user: alice
  name: alice-context
current-context: alice-context
kind: Config
preferences: {}
users:
- name: alice
  user:
    client-certificate-data: [cert]
    client-key-data: [key]
```

### NetworkPolicy basique

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: my-app
```

---

## 📞 Commandes d'urgence

```bash
# Redémarrer rapidement
kubectl rollout restart deployment/my-app

# Arrêter une app
kubectl scale deployment my-app --replicas=0

# Lancer rapidement
kubectl scale deployment my-app --replicas=3

# Supprimer un pod coincé
kubectl delete pod my-pod --grace-period=0 --force

# Voir tous les erreurs
kubectl get events -A --sort-by='.lastTimestamp' | grep -i error

# Drain un nœud
kubectl drain kubes-02 --ignore-daemonsets

# Uncordon un nœud
kubectl uncordon kubes-02
```

---

## 📚 Prochaines étapes

Consultez ces ressources si vous êtes bloqué :
- [Documentation Kubernetes officielle](https://kubernetes.io/docs/)
- [K3S documentation](https://k3s.io/)
- [Helm documentation](https://helm.sh/docs/)

---

**✅ Vous avez toutes les commandes et solutions courantes !**
