# 🎓 Cours 01 - Kubernetes Basics (2 heures)

## 📚 Table des matières

1. [Introduction](#introduction)
2. [Architecture Kubernetes](#architecture-kubernetes)
3. [Concepts Clés](#concepts-clés)
4. [Pod](#pod)
5. [Deployment](#deployment)
6. [Service](#service)
7. [Namespace](#namespace)
8. [Résumé](#résumé)

---

## 🎯 Introduction

### Durée : 2 heures
### Niveau : Débutant
### Prérequis : Connaître Docker

### Objectifs
À la fin de ce cours, vous saurez :
- ✅ Expliquer l'architecture de Kubernetes
- ✅ Maîtriser les concepts : Pod, Deployment, Service
- ✅ Déployer une application simple sur K8s

---

## 🏗️ Architecture Kubernetes

### Qu'est-ce que Kubernetes ?

**Kubernetes** (K8s) est un système d'orchestration de conteneurs créé par Google. C'est le "maestro" d'une symphonie de conteneurs.

#### Analogie

```
Kubernetes est comme un chef d'orchestre 🎼

├─ Les musiciens = Conteneurs (pods)
├─ Les instruments = Services (exposition)
├─ La partition = Manifest YAML (déclaration d'état)
├─ La baguette = Control Plane (gestion)
└─ L'auditorium = Cluster (ensemble)
```

### Que fait Kubernetes ?

#### 1. Déploiement Automatique
```
❌ Manuel : docker run sur 100 machines
✅ K8s : kubectl apply -f deployment.yaml (100 replicas)
```

#### 2. Scaling Automatique
```
5 utilisateurs → 1 pod
1000 utilisateurs → 50 pods
10 utilisateurs → 5 pods
```

#### 3. Gestion des Ressources
```
CPU libre ? → Déployer nouveau pod
Mémoire insuffisante ? → Arrêter pod moins important
Disque plein ? → Alerter admin
```

#### 4. Self-Healing
```
Pod crash ? → Redémarrer automatiquement
Nœud meurt ? → Migrer pods sur autre nœud
Service arrêté ? → Redéployer
```

#### 5. Rolling Updates
```
Version 1.0 (5 pods)
    ↓
Remplacer 1 pod par v1.1
Attendre que v1.1 soit prêt
    ↓
Remplacer tous les pods progressivement
    ↓
Version 1.1 (5 pods) sans interruption
```

---

## 🏢 Architecture Master-Worker

### Vue d'ensemble

```
┌─────────────────────────────────────────────┐
│         KUBERNETES CLUSTER                  │
├─────────────────────────────────────────────┤
│                                             │
│  MASTER (Control Plane)                    │
│  ┌──────────────────────────────────────┐  │
│  │ • API Server (9443)                  │  │
│  │ • etcd (base de données)             │  │
│  │ • Scheduler (placement)              │  │
│  │ • Controller Manager (boucles)       │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────┐  ┌──────────────────┐│
│  │ WORKER 1         │  │ WORKER 2         ││
│  ├──────────────────┤  ├──────────────────┤│
│  │ • Pods (turnent) │  │ • Pods (turnent) ││
│  │ • kubelet        │  │ • kubelet        ││
│  │ • kube-proxy     │  │ • kube-proxy     ││
│  │ • Runtime        │  │ • Runtime        ││
│  └──────────────────┘  └──────────────────┘│
│                                             │
└─────────────────────────────────────────────┘
```

### Composants du Master

#### API Server (kube-apiserver)

**Rôle** : Point d'entrée central du cluster

```
kubectl ---> API Server ---> etcd
   │             │             │
   │             ├─> Scheduler │
   │             │             │
   │             └─> Controller
   │
   └─> REST API (port 6443/9443)
```

**Responsabilités** :
- ✓ Accepter les requêtes kubectl
- ✓ Valider les manifests
- ✓ Sauvegarder dans etcd
- ✓ Informer les watchers

**Exemple** :
```bash
kubectl create deployment nginx --image=nginx

1. kubectl envoie → API Server (REST)
2. API Server valide le manifest
3. API Server sauvegarde dans etcd
4. API Server notifie le Scheduler
5. Scheduler crée les pods
```

#### etcd (Base de données)

**Rôle** : Stockage persistant de l'état du cluster

```
etcd (key-value store)
├─ /deployments/nginx
├─ /pods/nginx-abc123
├─ /services/my-service
└─ /configmaps/app-config
```

**Caractéristiques** :
- ✓ Fortement cohérent (toujours à jour)
- ✓ Distribué (multi-master)
- ✓ Persistant (survit aux redémarrages)
- ⚠️ À sauvegarder régulièrement

#### Scheduler (kube-scheduler)

**Rôle** : Décider où placer les pods

```
Pod non-assigné
    ↓
Scheduler lit les Pod specs
    ↓
Filtre les nœuds (ressources, contraintes)
    ↓
Score les meilleurs nœuds
    ↓
Assigne le pod au meilleur nœud
    ↓
Pod démarrage sur le worker
```

**Exemple** :
```yaml
Pod nginx spec :
  resources:
    requests:
      memory: 256Mi
      cpu: 100m

Nœud 1 : 500Mi libre ✓ (sélectionné)
Nœud 2 : 100Mi libre ✗ (insuffisant)
```

#### Controller Manager (kube-controller-manager)

**Rôle** : Boucles de contrôle pour maintenir l'état désiré

```
État actuel ≠ État désiré
    ↓
Controllers détectent la différence
    ↓
Controllers prennent action
    ↓
État actuel = État désiré
```

**Contrôleurs importants** :
- Deployment Controller : gère les replicas
- StatefulSet Controller : gère les pods avec état
- Service Controller : gère les endpoints
- Node Controller : surveille les nœuds

### Composants des Workers

#### Kubelet

**Rôle** : Agent du nœud, assure que les pods tournent

```
kubelet (daemon sur le worker)
├─ Reçoit spec des pods (du master)
├─ Crée/démarre/arrête les conteneurs
├─ Surveille la santé
└─ Reporte au master
```

**Tâches** :
- Créer les conteneurs (via runtime)
- Exécuter les probes (liveness, readiness)
- Monter les volumes
- Maintenir les logs
- Rapporter l'état

#### kube-proxy

**Rôle** : Networking au niveau du nœud

```
External traffic
    ↓ (port 30080)
kube-proxy (iptables/ipvs)
    ↓ (port-forward)
Service (10.43.x.x)
    ↓ (load-balance)
Pods (10.244.x.x)
```

**Responsabilités** :
- Load balancer pour les Services
- NAT (traduction d'adresses)
- Rule iptables/ipvs
- DNS resolution

#### Container Runtime

**Rôle** : Exécuter les conteneurs

```
Exemples :
├─ Docker (legacy)
├─ containerd (recommandé)
├─ CRI-O
└─ podman

K8s parle via CRI (Container Runtime Interface)
```

---

## 🔑 Concepts Clés

### 1. Pod

**Définition** : Plus petite unité déployable dans Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

**Caractéristiques** :
- ✓ 1+ conteneurs (généralement 1)
- ✓ Partage l'adresse IP (localhost entre conteneurs)
- ✓ Partage les volumes
- ✓ Durée de vie courte (éphémère)
- ✓ Pas de relance auto

**Pourquoi 1+ conteneurs ?**

```
Cas d'usage : sidecar pattern

Pod
├─ Container 1 : Application (port 8080)
└─ Container 2 : Logger (lit logs, envoie au serveur)

Les 2 containers partagent :
├─ Filesystem (/var/log)
├─ Réseau (localhost:8080)
└─ Variables d'environnement
```

### 2. ReplicaSet

**Définition** : Garantit qu'un nombre exact de replicas tournent

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3  # Toujours 3 pods
  selector:
    matchLabels:
      app: nginx
  template:
    # Spec du pod
```

**Comportement** :
```
Désiré : 3 pods
Actuel : 1 pod

ReplicaSet : "Je dois créer 2 pods"
    ↓
Crée 2 nouveaux pods
    ↓
Actuel : 3 pods ✓
```

### 3. Deployment

**Définition** : Gère les ReplicaSets et permet les mises à jour

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    # Spec du pod
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
```

**Avantages sur ReplicaSet** :
- Rolling updates (remplacer graduellement)
- Rollback (revenir à version précédente)
- Pause/resume déploiement
- Historique de déploiement

**Exemple** :
```
Deployment v1.19 (3 pods)
    ↓
kubectl set image ... nginx=nginx:1.20
    ↓
Deployment v1.20 (rolling update)
├─ Détruire 1 old pod
├─ Créer 1 new pod
├─ Attendre que new pod soit ready
├─ Répéter jusqu'à tous les pods updated
    ↓
Deployment v1.20 (3 pods) - Zéro downtime !
```

### 4. Service

**Définition** : Expose les pods à l'intérieur/extérieur du cluster

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 8080
```

**Types** :
- ClusterIP : Interne au cluster
- NodePort : Port sur chaque nœud
- LoadBalancer : IP externe
- ExternalName : DNS externe

### 5. Namespace

**Définition** : Isolation logique des ressources

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production

---
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  namespace: production  # Dans le namespace "production"
```

**Namespaces importants** :
- `default` : Par défaut
- `kube-system` : Composants K8s
- `kube-node-lease` : Health checks
- `kube-public` : Infos publiques

---

## 📦 Pod

### Création d'un Pod

#### Méthode 1 : Déclaratif (YAML)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: myapp
spec:
  containers:
  - name: my-container
    image: myimage:latest
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

Déployer :
```bash
kubectl apply -f pod.yaml
```

#### Méthode 2 : Impératif (CLI)

```bash
kubectl run my-pod --image=myimage:latest
```

### Cycle de vie d'un Pod

```
1. Pending
   ├─ Image en téléchargement
   ├─ Ressources en attente
   └─ Volume en montage

2. Running
   ├─ Conteneur démarré
   ├─ Liveness probe OK
   └─ Application prête

3. Succeeded / Failed / Unknown
   ├─ Conteneur arrêté
   ├─ Exit code
   └─ Logs disponibles
```

### Health Checks

#### Liveness Probe

**Détecte** : Le pod est-il mort ?

```yaml
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      failureThreshold: 3
```

**Comportement** :
```
HTTP GET /health
├─ 200-399 ✓ Alive
├─ 400+ ✗ Dead → Redémarrer
├─ Timeout ✗ Dead → Redémarrer
└─ 3 échecs → Redémarrer
```

#### Readiness Probe

**Détecte** : Le pod est-il prêt à recevoir du trafic ?

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Comportement** :
```
Startup (5s)
├─ Charger config
├─ Connecter BD
    ↓
Ready probe : /ready
├─ 200 ✓ Prêt → Accepter trafic
└─ 500 ✗ Pas prêt → Pas de trafic
```

---

## 📈 Deployment

### Créer un Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

### Vérifier le Deployment

```bash
# Voir les deployments
kubectl get deployments

# Voir les replicas
kubectl get replicasets

# Voir les pods
kubectl get pods

# Voir les détails
kubectl describe deployment nginx-deployment
```

### Mettre à jour l'image

```bash
# Approche 1 : Ligne de commande
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Approche 2 : Éditer le YAML
kubectl edit deployment nginx-deployment

# Approche 3 : Patch
kubectl patch deployment nginx-deployment -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.22"}]}}}}'
```

### Rolling Update

```
Ancien : nginx:1.21 (3 pods)
    ↓
Commande : set image nginx=1.22
    ↓
Démarrage rolling update (MaxUnavailable: 1)
    ↓
├─ Détruire 1 pod 1.21 (2 en service)
├─ Créer 1 pod 1.22 (test)
├─ Si OK, continuer
├─ Détruire 1 pod 1.21 (2 en service : 1 old + 1 new)
├─ Créer 1 pod 1.22
├─ Détruire 1 pod 1.21 (2 en service : 2 new)
├─ Créer 1 pod 1.22
    ↓
Fin : nginx:1.22 (3 pods) ✓
Zéro downtime ! 
```

### Rollback

```bash
# Voir l'historique
kubectl rollout history deployment/nginx-deployment

# Revenir à la version précédente
kubectl rollout undo deployment/nginx-deployment

# Revenir à une révision spécifique
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

---

## 🌐 Service

### Types de Services

#### ClusterIP (Défaut)

```
Pod1 (10.244.1.1)
Pod2 (10.244.2.1)
Pod3 (10.244.3.1)
    ↓ (labels: app=nginx)
Service ClusterIP (10.43.0.100)
    ↓ (discovered)
Autres pods : curl http://service-name
```

**Cas d'usage** : Microservices internes, pas d'accès externe

#### NodePort

```
External (80)
    ↓
Node1:30080 ⊗ Node2:30080 ⊗ Node3:30080
    ↓
Service NodePort (10.43.0.100)
    ↓
Pods nginx
```

**Cas d'usage** : Dev, test, sans load balancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80          # Port du service
    targetPort: 8080  # Port du pod
    nodePort: 30080   # Port de la node (30000-32767)
```

Accès : `http://<node-ip>:30080`

#### LoadBalancer

```
Internet
    ↓
External LoadBalancer (50.1.2.3)
    ↓
Service LoadBalancer (10.43.0.100)
    ↓
Pods
```

**Cas d'usage** : Production, public APIs

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 8080
```

### Découverte de Services (DNS)

**Nom du service** :
```
<service-name>.<namespace>.svc.cluster.local
```

**Exemples** :
```
nginx-service (même namespace)
    ↓ Résout à
10.43.0.100

nginx-service.default.svc.cluster.local (FQDN)
    ↓ Résout à
10.43.0.100

nginx-service.other-ns.svc.cluster.local (autre namespace)
    ↓ Résout à
10.43.0.200
```

---

## 📂 Namespace

### Créer un Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

Ou :
```bash
kubectl create namespace production
```

### Isoler les Ressources

```
Cluster
├─ Namespace: default
│  └─ Pods: pod1, pod2
├─ Namespace: production
│  └─ Pods: prod-app-1, prod-app-2
└─ Namespace: monitoring
   └─ Pods: prometheus, grafana
```

### Quotas et Limites

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "100"
```

---

## 📋 Résumé

### Concepts clés à retenir

| Concept | Rôle | Niveau |
|---------|------|--------|
| **Pod** | Unité exécution | 1 conteneur |
| **Deployment** | Gestion replicas | 1:N pods |
| **ReplicaSet** | Garantit replicas | Utilisé par Deployment |
| **Service** | Expose pods | Interne/Externe |
| **Namespace** | Isolation logique | Multi-tenant |

### Architecture à retenir

```
Deployment (manifeste)
    ↓
ReplicaSet (gestion)
    ↓
Pods (exécution) ← kubelet
    ↓
Conteneurs (Docker)
    ↓
Service (exposition) ← kube-proxy
```

### Workflow typique

```
1. Écrire manifest YAML
2. kubectl apply
3. API Server sauvegarde
4. Scheduler place les pods
5. kubelet démarre les pods
6. kube-proxy expose via Service
7. Monitoring et self-healing
```

---

## 🧪 Quiz d'auto-évaluation

- [ ] Je peux expliquer l'architecture Master-Worker
- [ ] Je sais ce qu'est un Pod et ses propriétés
- [ ] Je comprends Deployment et ReplicaSet
- [ ] Je sais les types de Services
- [ ] Je peux décrire un Namespace

**Si vous avez tout coché, vous êtes prêt pour le cours 02 !** ✅

---

## 📚 Pour approfondir

- Lire : `02_k3s_architecture.md` (K3S allégée)
- Lire : `03_docker_images.md` (Images de base)
- Pratiquer : Créer un Deployment avec Service

---

*Fin du cours 01. Bravo ! 🎉*
