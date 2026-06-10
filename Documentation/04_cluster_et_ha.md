# 04 - Cluster K3S et Haute Disponibilité (Jobs 03 & 04)

## 🎯 Objectif
Créer un **cluster K3S** avec 1 master et 2 workers, puis implémenter la **haute disponibilité (HA)** avec replicas et failover automatique.

## 📋 Table des matières
1. [Architecture cluster](#architecture-cluster)
2. [Joindre les workers](#joindre-les-workers)
3. [Valider le cluster](#valider-le-cluster)
4. [Haute disponibilité](#haute-disponibilité)
5. [Tester le failover](#tester-le-failover)

---

## 🏗️ Architecture cluster

### Avant (3 clusters indépendants)
```
kubes-01: K3S (standalone)
kubes-02: K3S (standalone)
kubes-03: K3S (standalone)
```

### Après (1 cluster unifié)
```
┌───────────────────────────────────────┐
│      Cluster Kubernetes K3S           │
├───────────────────────────────────────┤
│ Master (Control Plane)                │
│ kubes-01.local (10.0.0.10)            │
│ - etcd, API Server, Scheduler         │
│                                       │
│ ┌─────────────────────────────────┐   │
│ │ Workers                         │   │
│ │ kubes-02 (10.0.0.11) - Ready    │   │
│ │ kubes-03 (10.0.0.12) - Ready    │   │
│ └─────────────────────────────────┘   │
└───────────────────────────────────────┘
```

---

## 🔗 Joindre les workers (Job 03)

### Étape 1 : Récupérer le token du master

Sur **kubes-01** (le master) :

```bash
# Récupérer le token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo "Token: $TOKEN"

# Récupérer l'URL du master
MASTER_URL="https://kubes-01.local:6443"
echo "Master URL: $MASTER_URL"

# Sauvegarder pour plus tard
echo "TOKEN=$TOKEN" > /tmp/k3s-token.txt
echo "MASTER_URL=$MASTER_URL" >> /tmp/k3s-token.txt
```

### Étape 2 : Arrêter K3S sur les workers

Sur **kubes-02 et kubes-03**, arrêter l'instance K3S autonome :

```bash
# Arrêter K3S en tant que server
sudo systemctl stop k3s
sudo systemctl disable k3s

# Nettoyer les fichiers (optionnel)
sudo rm -rf /var/lib/rancher/k3s
```

### Étape 3 : Joindre les workers au cluster

Sur **kubes-02** :

```bash
# Variables (remplacez par les vraies valeurs)
TOKEN="K10abcdef...xyz::server:..."    # Depuis kubes-01
MASTER_URL="https://kubes-01.local:6443"
NODE_NAME="kubes-02"

# Installer K3S en tant que worker
curl -sfL https://get.k3s.io | \
  K3S_URL=$MASTER_URL \
  K3S_TOKEN=$TOKEN \
  K3S_NODE_NAME=$NODE_NAME \
  sh -

# Vérifier que le service est actif
sudo systemctl status k3s-agent
```

Sur **kubes-03** :

```bash
TOKEN="K10abcdef...xyz::server:..."
MASTER_URL="https://kubes-01.local:6443"
NODE_NAME="kubes-03"

curl -sfL https://get.k3s.io | \
  K3S_URL=$MASTER_URL \
  K3S_TOKEN=$TOKEN \
  K3S_NODE_NAME=$NODE_NAME \
  sh -

sudo systemctl status k3s-agent
```

### Étape 4 : Vérifier l'adhésion au cluster

Sur **kubes-01** (le master) :

```bash
# Voir tous les nœuds
kubectl get nodes
# Expected:
# NAME       STATUS   ROLES                  AGE   VERSION
# kubes-01   Ready    control-plane,master   5m    v1.28.0
# kubes-02   Ready    <none>                 30s   v1.28.0
# kubes-03   Ready    <none>                 30s   v1.28.0

# Voir les infos détaillées
kubectl get nodes -o wide

# Décrire un nœud
kubectl describe node kubes-02
```

---

## ✅ Valider le cluster

### Test 1 : Tous les nœuds sont prêts

```bash
kubectl get nodes
# Tous doivent avoir STATUS = "Ready"
```

### Test 2 : Les pods système sont distribués

```bash
# Afficher tous les pods avec leurs nœuds
kubectl get pods -A -o wide
# Vérifier que les pods sont sur les 3 nœuds
```

### Test 3 : Le réseau fonctionne entre les nœuds

```bash
# Depuis kubes-01, faire un ping à un pod sur kubes-02
POD=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- ping -c 1 10.0.0.11
```

### Test 4 : Déployer un test simple

```bash
# Créer un test sur chaque nœud
kubectl run test-node1 --image=busybox --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"kubes-01"}}}' -- sleep 3600
kubectl run test-node2 --image=busybox --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"kubes-02"}}}' -- sleep 3600
kubectl run test-node3 --image=busybox --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"kubes-03"}}}' -- sleep 3600

# Vérifier
kubectl get pods -o wide

# Nettoyer
kubectl delete pod test-node1 test-node2 test-node3
```

---

## 🔄 Haute Disponibilité (Job 04)

### Concept : Replicas

Un **replica** est une copie d'un pod. Avec 3 replicas :
- Si 1 pod crash → 2 continuent à tourner
- Kubernetes relance automatiquement le pod manquant
- Les requêtes sont réparties (load balancing)

### Étape 1 : Supprimer les apps existantes

```bash
# Supprimer les deployments
kubectl delete deployment nginx-deployment apache-deployment mariadb-deployment

# Ou
kubectl delete -f all-apps.yaml

# Vérifier
kubectl get pods
# Doit être vide (sauf pods système)
```

### Étape 2 : Redéployer avec HA (replicas)

Créer un fichier `apps-ha.yaml` avec des replicas :

```yaml
---
# NGINX avec HA (3 replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3  # ← Haute disponibilité
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - nginx
              topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx

---
# APACHE avec HA (3 replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  labels:
    app: apache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - apache
              topologyKey: kubernetes.io/hostname
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: apache

---
# MARIADB (pas de replicas pour maintenant)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
  labels:
    app: mariadb
spec:
  replicas: 1  # MariaDB nécessite du stockage persistant
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:latest
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "root"
        - name: MYSQL_DATABASE
          value: "myapp"
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
spec:
  type: ClusterIP
  ports:
  - port: 3306
    targetPort: 3306
  selector:
    app: mariadb
```

Déployer :

```bash
kubectl apply -f apps-ha.yaml

# Vérifier
kubectl get deployments
kubectl get pods -o wide
kubectl get svc
```

### Étape 3 : Vérifier la distribution des replicas

```bash
# Voir comment les pods sont répartis
kubectl get pods -o wide
# Expected : 3 pods nginx sur 3 nœuds différents
#           3 pods apache sur 3 nœuds différents

# Voir les détails d'un deployment
kubectl describe deployment nginx-deployment
```

---

## 🧪 Tester le failover

### Test 1 : Arrêter un worker et vérifier le failover

```bash
# Sur kubes-02, arrêter K3S
ssh kubes-02.local
sudo systemctl stop k3s-agent

# Sur kubes-01, regarder ce qui se passe
kubectl get pods -o wide --watch
# Vous devriez voir les pods sur kubes-02 être schedulés sur kubes-01/kubes-03

# Attendre quelques secondes, puis:
kubectl get pods -o wide
# Les pods devraient avoir changé de nœud

# Redémarrer kubes-02
ssh kubes-02.local
sudo systemctl start k3s-agent

# Attendre que kubes-02 redevienne Ready
kubectl get nodes --watch
```

### Test 2 : Arrêter un pod et vérifier la rédemande

```bash
# Voir le pod actuel
kubectl get pods -l app=nginx
# Expected : 3 pods

# Tuer un pod
POD=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD

# Vérifier immédiatement
kubectl get pods -l app=nginx
# Vous verrez un pod en état "Terminating" et un nouveau en "Pending"

# Attendre quelques secondes
kubectl get pods -l app=nginx
# Expected : 3 pods running
```

### Test 3 : Tester la continuité de service

```bash
# Vérifier que le service fonctionne
# Pod Nginx tourne sur kubes-02
kubectl get pods -o wide -l app=nginx | grep kubes-02

# Supprimer ce pod
kubectl delete pod [POD_NAME]

# Tester immédiatement l'accès au service
while true; do
  curl -s http://localhost:80 | head -n1
  sleep 1
done

# Vous devriez voir du "nginx" sans interruption
# (l'autre pod du service continue à répondre)
```

### Test 4 : Arrêter le master et vérifier la résilience

⚠️ **Test avancé** - le cluster continue de fonctionner sans le master !

```bash
# Sur kubes-01, arrêter K3S
ssh kubes-01.local
sudo systemctl stop k3s

# Sur kubes-02, essayer de utiliser kubectl
# ❌ Kubectl ne peut pas se connecter (pas de master)

# Mais les pods continuent à tourner !
# (car les workers n'ont pas besoin du master pour lancer les pods)

# Redémarrer le master
ssh kubes-01.local
sudo systemctl start k3s

# kubectl redémarre du côté master
kubectl get pods
# Les pods sont toujours là
```

---

## 📊 État après cette étape

```
Nœuds du cluster:
  ✓ kubes-01 (Ready, master)
  ✓ kubes-02 (Ready, worker)
  ✓ kubes-03 (Ready, worker)

Deployments avec HA:
  ✓ nginx-deployment (3 replicas)
  ✓ apache-deployment (3 replicas)
  ✓ mariadb-deployment (1 replica)

Tests:
  ✓ Failover d'un nœud réussi
  ✓ Redémarrage automatique de pods
  ✓ Service continu même avec nœud down
```

---

## 📝 Commandes importantes

```bash
# Joindre un worker
curl -sfL https://get.k3s.io | \
  K3S_URL=https://kubes-01.local:6443 \
  K3S_TOKEN=... \
  K3S_NODE_NAME=kubes-02 \
  sh -

# Voir les nœuds
kubectl get nodes -o wide

# Voir les pods répartis
kubectl get pods -o wide

# Scaler un deployment
kubectl scale deployment nginx-deployment --replicas=5

# Voir les événements
kubectl get events -A

# Vérifier la HA
kubectl rollout status deployment/nginx-deployment
```

---

## ⚠️ Points d'attention

- ⚠️ **Token** : À récupérer avant d'arrêter K3S sur les workers
- ⚠️ **Pod Anti-Affinity** : Assure que les replicas ne sont pas sur le même nœud
- ⚠️ **Probes** : Liveness et readiness permettent à K8s de gérer les pods malades
- ⚠️ **MariaDB** : Reste avec 1 replica (volume persistant à l'étape suivante)

---

## 📚 Prochaines étapes

Une fois que :
- ✓ Cluster formé avec 3 nœuds (1 master + 2 workers)
- ✓ Replicas déployés avec HA
- ✓ Failover testé avec succès

**Passez à : `05_stockage_persistant.md`** pour configurer les volumes persistants.

---

## 📝 Journal de bord

```
Date : [date]
Cluster formation :
  - kubes-01 (Master) : [OK/NOK]
  - kubes-02 (Worker) : [OK/NOK]
  - kubes-03 (Worker) : [OK/NOK]

Tests HA :
  - Arrêt kubes-02 : [OK/NOK]
  - Failover réussi : [OK/NOK]
  - Redémarrage pods : [OK/NOK]
  - Service continu : [OK/NOK]

Observations:
  - [observation]
```

---

**✅ Le cluster est opérationnel avec HA ! Passons au stockage persistant.**
