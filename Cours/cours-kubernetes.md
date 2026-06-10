# 📖 Cours Kubernetes - Concepts Fondamentaux

## 🎯 Objectifs de ce cours

Comprendre les **concepts clés** de Kubernetes et K3S avant de les mettre en pratique.

---

## 📌 Partie 1 : Qu'est-ce que Kubernetes ?

### Définition simple
**Kubernetes** (K8s) est un **système d'orchestration de conteneurs** qui automatise le déploiement, la scalabilité et la gestion des applications en conteneurs.

### Pourquoi Kubernetes ?

| Problème | Solution Kubernetes |
|----------|-------------------|
| Déployer manuellement des conteneurs | Déploiement automatisé |
| Gérer les pannes | Auto-réparation (redémarrage des conteneurs) |
| Distribuer le trafic | Load balancing intégré |
| Sauvegarder les données | Volumes persistants |
| Gérer les secrets/config | ConfigMaps et Secrets |

### Comparaison rapide

```
Docker = conteneur seul (1 machine)
Docker Swarm = orchestration légère (plusieurs machines)
Kubernetes = orchestration complète et professionnelle (plusieurs machines)
K3S = Kubernetes léger (parfait pour l'apprentissage)
```

---

## 📌 Partie 2 : Architecture Kubernetes

### Composants principales

#### 1️⃣ **Master (Control Plane)**
Le "cerveau" du cluster. Décide quoi faire et où.

Composants :
- **API Server** : Interface pour communiquer avec K8s
- **etcd** : Base de données du cluster
- **Scheduler** : Décide sur quel nœud déployer les pods
- **Controller Manager** : S'assure que l'état actuel = état désiré

#### 2️⃣ **Workers (Nœuds)**
Les "exécutants". Exécutent les applications.

Composants par nœud :
- **Kubelet** : Agent qui gère les conteneurs
- **Container Runtime** : Docker, containerd, etc.
- **kube-proxy** : Gère la mise en réseau

#### 3️⃣ **Cluster**
= 1 Master + N Workers

```
┌─────────────────────────────────────┐
│         KUBERNETES CLUSTER          │
├─────────────────────────────────────┤
│     MASTER (Control Plane)          │
│  ┌─────────────────────────────┐   │
│  │ API Server | Scheduler      │   │
│  │ etcd | Controller Manager   │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│ WORKER 1          WORKER 2          │
│ ┌──────────┐    ┌──────────┐       │
│ │  Pods    │    │  Pods    │       │
│ │ Kubelet  │    │ Kubelet  │       │
│ └──────────┘    └──────────┘       │
└─────────────────────────────────────┘
```

---

## 📌 Partie 3 : Concepts Clés

### 🟦 Pod
**Définition** : Plus petite unité déployable = conteneur(s)

```yaml
# Un pod simple (1 conteneur)
apiVersion: v1
kind: Pod
metadata:
  name: mon-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

**Points clés** :
- 1 pod = 1+ conteneurs
- Partagent le réseau (même adresse IP)
- Éphémères (meurent et renaissent)

### 🟦 Deployment
**Définition** : Gère les pods (création, mise à jour, suppression)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
spec:
  replicas: 3  # Crée 3 copies du pod
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
        image: nginx:latest
```

**Points clés** :
- Décrit l'état désiré (3 pods nginx)
- K8s assure cet état (redémarre si crash)
- Permet les mises à jour sans interruption

### 🟦 Service
**Définition** : Expose les pods à l'intérieur/extérieur du cluster

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer  # Accessible de l'extérieur
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**Types de services** :
- `ClusterIP` : Accessible seulement dans le cluster
- `NodePort` : Accessible sur un port de chaque nœud
- `LoadBalancer` : Accessible via une IP externe

### 🟦 Volume
**Définition** : Stockage persistant pour les données

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data"
```

**Points clés** :
- Sans volume : données perdues si le pod meurt
- Avec volume : données sauvegardées

### 🟦 ConfigMap
**Définition** : Stocke des configurations (non-sensibles)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "localhost"
  DATABASE_PORT: "3306"
```

### 🟦 Secret
**Définition** : Stocke des données sensibles (passwords, tokens)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encodé
```

### 🟦 Namespace
**Définition** : "Dossier" logique pour isoler les ressources

```bash
# Créer un namespace
kubectl create namespace production

# Déployer dans ce namespace
kubectl apply -f app.yaml -n production
```

---

## 📌 Partie 4 : Cycle de Vie d'une Application

### Phase 1 : Création (Deployment)
```bash
kubectl apply -f deployment.yaml
```

### Phase 2 : Déploiement des Pods
K8s crée les pods sur les workers disponibles.

### Phase 3 : Exposition (Service)
```bash
kubectl apply -f service.yaml
```

### Phase 4 : Fonctionnement
- L'app tourne sur les pods
- Si un pod meurt → Deployment le redémarre
- Si un nœud meurt → Pods migrés sur autre nœud

### Phase 5 : Mise à jour
```bash
kubectl set image deployment/my-app app=my-app:v2
```

K8s échange les anciens pods par les nouveaux sans interruption.

---

## 📌 Partie 5 : Haute Disponibilité (HA)

### Concept
L'application reste accessible même si un/des nœuds tombent.

### Stratégies

#### 1️⃣ **Replicas**
Plusieurs copies du même pod sur différents nœuds.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3  # 3 copies
  template:
    spec:
      containers:
      - name: app
        image: my-app:latest
```

**Avantage** : Si 1 nœud meurt, 2 autres continuent.

#### 2️⃣ **Multi-Master**
Plusieurs master pour redondance.

```
┌───────────────────────────────┐
│ MASTER 1   MASTER 2   MASTER 3│
└────┬──────────┬──────────┬────┘
     │          │          │
┌────▼──────────▼──────────▼────┐
│ WORKER 1   WORKER 2   WORKER 3│
└────────────────────────────────┘
```

---

## 📌 Partie 6 : Qu'est-ce que K3S ?

### Différence K3S vs Kubernetes

| Aspect | Kubernetes | K3S |
|--------|-----------|-----|
| Taille | 500+ MB | ~40 MB |
| RAM | 2GB+ | 512MB |
| Use case | Production | Apprentissage, edge |
| Complexité | Haute | Basse |

### Avantages de K3S
✅ Facile à installer
✅ Léger (idéal pour VMs)
✅ Inclut StorageClass par défaut
✅ 100% compatible Kubernetes
✅ Parfait pour apprendre

### Installation simple
```bash
curl -sfL https://get.k3s.io | sh -
```

---

## 📌 Partie 7 : RBAC (Contrôle d'Accès)

### Concept
Qui peut faire quoi dans le cluster ?

### Composants

#### Role (Permissions)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

#### RoleBinding (Assignation)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: User
  name: jean@example.com
```

---

## 📌 Partie 8 : Helm (Gestionnaire de Packages)

### Qu'est-ce que Helm ?
**Helm = apt-get/npm pour Kubernetes**

Au lieu d'écrire des fichiers YAML complexes, on utilise des **charts** pré-faits.

### Exemple
```bash
# Chercher une app
helm search repo nginx

# L'installer
helm install my-nginx stable/nginx

# La mettre à jour
helm upgrade my-nginx stable/nginx --set replicas=5

# La supprimer
helm uninstall my-nginx
```

### Chart = Package
Un chart = bundle de fichiers YAML pré-configurés.

```
my-chart/
├── Chart.yaml          # Infos du chart
├── values.yaml         # Valeurs par défaut
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
```

---

## 🎓 Résumé Visuel

```
┌────────────────────────────────────────┐
│      VOTRE APPLICATION                 │
├────────────────────────────────────────┤
│  Helm Chart                            │
│  (définit l'installation)              │
├────────────────────────────────────────┤
│  Deployment                            │
│  (gère les pods)                       │
├────────────────────────────────────────┤
│  Pod (contient les conteneurs)         │
│  ┌──────────────────────────────────┐ │
│  │ Conteneur 1  │  Conteneur 2      │ │
│  │ (nginx)      │  (app)            │ │
│  └──────────────────────────────────┘ │
├────────────────────────────────────────┤
│  Volume (stockage persistant)          │
│  ConfigMap (config)                    │
│  Secret (identifiants)                 │
│  Service (exposition)                  │
└────────────────────────────────────────┘
```

---

## 📚 Ressources Supplémentaires

### Documentation officielle
- https://kubernetes.io/docs/
- https://docs.k3s.io/

### Tutoriels interactifs
- Katacoda Kubernetes
- Play with Kubernetes

### Commandes essentielles
```bash
kubectl get nodes                    # Voir les nœuds
kubectl get pods                     # Voir les pods
kubectl describe pod <nom>           # Détails du pod
kubectl logs <pod-name>              # Logs
kubectl exec -it <pod> -- /bin/bash  # Entrer dans le pod
```

---

**Fin du cours. Vous êtes prêts pour la pratique !** 🚀
