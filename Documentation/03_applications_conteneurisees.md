# 03 - Applications Conteneurisées (Job 02)

## 🎯 Objectif
Déployer les applications **nginx**, **Apache** et **MariaDB** en tant que pods Kubernetes sur chaque VM.

## 📋 Table des matières
1. [Concepts Kubernetes](#concepts-kubernetes)
2. [Déployer Nginx](#déployer-nginx)
3. [Déployer Apache](#déployer-apache)
4. [Déployer MariaDB](#déployer-mariadb)
5. [Vérification](#vérification)
6. [Gestion des applications](#gestion-des-applications)

---

## 💡 Concepts Kubernetes

### Pod
- Unité la plus petite dans Kubernetes
- Contient un ou plusieurs conteneurs
- Partagent réseau, stockage, IP

### Deployment
- Gère les pods
- Permet scalabilité et mises à jour
- Crée les ReplicaSets

### Service
- Expose les pods à l'intérieur/extérieur du cluster
- Types : ClusterIP, NodePort, LoadBalancer

### Image Docker
- Modèle pour créer des conteneurs
- Format : `registry/namespace/nom:tag`
- Exemples : `nginx:latest`, `mysql:8.0`

---

## 🚀 Déployer Nginx

### Méthode 1 : Ligne de commande (simple)

```bash
# Créer un deployment Nginx avec 1 replica
kubectl create deployment nginx --image=nginx:latest

# Vérifier
kubectl get deployments
kubectl get pods

# Exposer le service (NodePort)
kubectl expose deployment nginx --type=NodePort --port=80

# Voir le port assigné
kubectl get svc nginx
```

### Méthode 2 : Fichier YAML (recommandé)

Créer un fichier `nginx-deployment.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1  # Augmenter pour haute disponibilité
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
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: nginx
```

Déployer :

```bash
# Appliquer le manifeste
kubectl apply -f nginx-deployment.yaml

# Vérifier
kubectl get deployments
kubectl get pods
kubectl get svc

# Accéder au service
# Sur kubes-01 : http://kubes-01.local:30080
# Ou : curl http://localhost:30080
```

### Test Nginx

```bash
# Vérifier que Nginx tourne
kubectl get pods -l app=nginx
kubectl logs deployment/nginx-deployment

# Tester l'accès
curl http://localhost:30080
# Expected: HTML de Nginx

# Accès depuis une autre VM
curl http://kubes-01.local:30080
```

---

## 🚀 Déployer Apache

Créer un fichier `apache-deployment.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  labels:
    app: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
  labels:
    app: apache
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
  selector:
    app: apache
```

Déployer :

```bash
# Appliquer le manifeste
kubectl apply -f apache-deployment.yaml

# Vérifier
kubectl get deployments
kubectl get pods
kubectl get svc

# Tester
curl http://localhost:30081
```

---

## 🗄️ Déployer MariaDB

### Attention : MariaDB demande du stockage persistant

Pour l'instant, déployer une version simple (sans volume persistant) :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
  labels:
    app: mariadb
spec:
  replicas: 1
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
        - name: MYSQL_USER
          value: "appuser"
        - name: MYSQL_PASSWORD
          value: "apppass"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
  labels:
    app: mariadb
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
# Appliquer le manifeste
kubectl apply -f mariadb-deployment.yaml

# Vérifier
kubectl get deployments
kubectl get pods
kubectl get svc

# Voir les logs
kubectl logs deployment/mariadb-deployment
```

### Tester MariaDB

```bash
# Se connecter au pod
kubectl exec -it deployment/mariadb-deployment -- mysql -uroot -proot

# Ou : exécuter une commande
kubectl exec deployment/mariadb-deployment -- mysql -uroot -proot -e "SHOW DATABASES;"

# Quitter
exit
```

---

## ✅ Vérification

### Check 1 : Tous les deployments tournent

```bash
kubectl get deployments
# Expected:
# NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment       1/1     1            1           2m
# apache-deployment      1/1     1            1           2m
# mariadb-deployment     1/1     1            1           2m
```

### Check 2 : Tous les pods sont Running

```bash
kubectl get pods
# Expected: STATUS = Running pour tous

# Détails
kubectl get pods -o wide
```

### Check 3 : Services exposés

```bash
kubectl get svc
# Expected:
# NAME               TYPE      CLUSTER-IP    EXTERNAL-IP   PORT(S)
# nginx-service      NodePort  10.43.x.x     <none>        80:30080/TCP
# apache-service     NodePort  10.43.y.y     <none>        80:30081/TCP
# mariadb-service    ClusterIP 10.43.z.z     <none>        3306/TCP
```

### Check 4 : Accès aux services

```bash
# Nginx
curl http://localhost:30080
curl http://kubes-01.local:30080

# Apache
curl http://localhost:30081
curl http://kubes-02.local:30081

# MariaDB (depuis le cluster)
kubectl exec -it deployment/mariadb-deployment -- mysql -uroot -proot -e "SELECT 'MariaDB OK';"
```

---

## 📋 Fichiers YAML consolidés

Créer un fichier unique `all-apps.yaml` :

```yaml
---
# NGINX DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
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
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: nginx

---
# APACHE DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  labels:
    app: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
  selector:
    app: apache

---
# MARIADB DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
  labels:
    app: mariadb
spec:
  replicas: 1
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
        - name: MYSQL_USER
          value: "appuser"
        - name: MYSQL_PASSWORD
          value: "apppass"
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

Déployer tout d'un coup :

```bash
kubectl apply -f all-apps.yaml
```

---

## 🔧 Gestion des applications

### Voir les ressources

```bash
# Deployments
kubectl get deployments
kubectl describe deployment nginx-deployment

# Pods
kubectl get pods
kubectl describe pod [POD_NAME]

# Services
kubectl get svc
kubectl describe svc nginx-service
```

### Voir les logs

```bash
# Logs d'un pod
kubectl logs [POD_NAME]

# Logs d'un deployment
kubectl logs deployment/nginx-deployment

# Logs en temps réel
kubectl logs -f deployment/nginx-deployment

# Logs des conteneurs précédents (si crash)
kubectl logs [POD_NAME] --previous
```

### Exécuter des commandes dans un pod

```bash
# Accès interactif
kubectl exec -it [POD_NAME] -- /bin/bash

# Commande unique
kubectl exec [POD_NAME] -- ls -la
```

### Scaler un deployment

```bash
# Augmenter à 3 replicas
kubectl scale deployment nginx-deployment --replicas=3

# Vérifier
kubectl get deployments
kubectl get pods
```

### Supprimer une application

```bash
# Supprimer un deployment
kubectl delete deployment nginx-deployment

# Supprimer un service
kubectl delete svc nginx-service

# Supprimer tout depuis un fichier
kubectl delete -f all-apps.yaml
```

---

## 📊 État attendu après cette étape

```
Deployments:
  ✓ nginx-deployment (1/1)
  ✓ apache-deployment (1/1)
  ✓ mariadb-deployment (1/1)

Services:
  ✓ nginx-service (NodePort 30080)
  ✓ apache-service (NodePort 30081)
  ✓ mariadb-service (ClusterIP)

Accès:
  ✓ curl http://localhost:30080 → Nginx OK
  ✓ curl http://localhost:30081 → Apache OK
  ✓ MariaDB accessible via kubectl exec
```

---

## 💾 Sauvegarder vos fichiers

```bash
# Créer un dossier pour les manifests
mkdir -p ~/kubernetes/manifests

# Copier les fichiers YAML
cp nginx-deployment.yaml ~/kubernetes/manifests/
cp apache-deployment.yaml ~/kubernetes/manifests/
cp mariadb-deployment.yaml ~/kubernetes/manifests/
cp all-apps.yaml ~/kubernetes/manifests/
```

---

## ⚠️ Points d'attention

- ⚠️ **MariaDB** : Demande du stockage (à faire à l'étape 05)
- ⚠️ **Passwords** : Ne pas coder en dur (utiliser des Secrets - étape 07)
- ⚠️ **Images** : Docker téléchargera les images au premier déploiement
- ⚠️ **Replicas** : À augmenter après mise en cluster (étape 04)

---

## 📚 Prochaines étapes

Une fois que :
- ✓ Nginx déployé et accessible
- ✓ Apache déployé et accessible
- ✓ MariaDB déployé et fonctionnel
- ✓ Les 3 apps tournent sur chaque VM

**Passez à : `04_cluster_et_ha.md`** pour créer le cluster K3S (1 master + 2 workers).

---

## 📝 Journal de bord

```
Date : [date]
Déploiements effectués :
  - Nginx : [timestamp] - Status: [OK/NOK]
  - Apache : [timestamp] - Status: [OK/NOK]
  - MariaDB : [timestamp] - Status: [OK/NOK]

Tests :
  - Nginx accessible : [OK/NOK]
  - Apache accessible : [OK/NOK]
  - MariaDB connecté : [OK/NOK]

Observations :
  - [observation 1]
  - [observation 2]
```

---

**✅ Les applications sont déployées ! Passons au cluster.**
