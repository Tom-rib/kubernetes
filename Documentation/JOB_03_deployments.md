# JOB 03 — Déployer les Applications

**Objectif** : Déployer 3 applications conteneurisées (Nginx, Apache, MariaDB) avec Services exposés.

**Durée estimée** : 25 minutes  
**Prérequis** : JOB 02 complété (cluster opérationnel)

---

## 📦 Applications à Déployer

| App | Image | Port | Type | Objectif |
|-----|-------|------|------|----------|
| **Nginx** | `nginx:latest` | 80/443 | Stateless web server | Application légère |
| **Apache** | `httpd:latest` | 80 | Stateless web server | Multi-conteneur |
| **MariaDB** | `mariadb:latest` | 3306 | Stateful database | Données persistantes |

---

## 🎯 Approche Déclarative (Kubernetes-native)

Plutôt que des commandes `kubectl create`, nous utilisons des **manifestes YAML** (Deployments + Services).

### Avantages :
- ✅ Reproductible
- ✅ Versionnable (Git)
- ✅ Documenté
- ✅ Production-ready

---

## 🚀 Étape 1 : Déployer Nginx

### Créer le manifest `nginx-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
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
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
```

### Appliquer le manifest

```bash
# Sur le master (kubes-01)
sudo k3s kubectl apply -f nginx-deployment.yaml
```

### Vérifier le déploiement

```bash
# Vérifier le Deployment
sudo k3s kubectl get deployment nginx

# Vérifier les Pods
sudo k3s kubectl get pods | grep nginx

# Vérifier le Service
sudo k3s kubectl get svc nginx-service
```

### Tester l'accès

```bash
# Depuis n'importe quel nœud
curl http://192.168.1.11:30080

# Doit retourner la page par défaut Nginx (HTML)
```

---

## 🚀 Étape 2 : Déployer Apache

### Créer le manifest `apache-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
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
      - name: httpd
        image: httpd:latest
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
  labels:
    app: apache
spec:
  type: NodePort
  selector:
    app: apache
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30081
```

### Appliquer le manifest

```bash
sudo k3s kubectl apply -f apache-deployment.yaml
```

### Tester l'accès

```bash
curl http://192.168.1.11:30081
# Doit retourner "It works!"
```

---

## 🗄️ Étape 3 : Déployer MariaDB

### Créer le manifest `mariadb-deployment.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mariadb-init
data:
  init.sql: |
    CREATE DATABASE IF NOT EXISTS appdb;
    CREATE USER 'appuser'@'%' IDENTIFIED BY 'apppass';
    GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
    FLUSH PRIVILEGES;
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
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
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpass"
        - name: MYSQL_DATABASE
          value: "appdb"
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
        volumeMounts:
        - name: mariadb-init
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: mariadb-init
        configMap:
          name: mariadb-init
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
  labels:
    app: mariadb
spec:
  type: ClusterIP
  selector:
    app: mariadb
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
```

### Appliquer le manifest

```bash
sudo k3s kubectl apply -f mariadb-deployment.yaml
```

### Vérifier le statut

```bash
# Attendre que le pod soit Running (2-3 minutes)
sudo k3s kubectl get pods | grep mariadb

# Une fois Running, vérifier la base de données
sudo k3s kubectl exec -it deployment/mariadb -- mysql -u root -prootpass -e "SHOW DATABASES;"
```

---

## 🧪 Vérification Complète (JOB 03)

```bash
# 1. Lister tous les Deployments
sudo k3s kubectl get deployments

# 2. Lister tous les Pods
sudo k3s kubectl get pods -o wide

# 3. Lister tous les Services
sudo k3s kubectl get svc

# 4. Vérifier les logs Nginx
sudo k3s kubectl logs deployment/nginx

# 5. Vérifier les logs Apache
sudo k3s kubectl logs deployment/apache

# 6. Vérifier les logs MariaDB
sudo k3s kubectl logs deployment/mariadb

# 7. Test HTTP Nginx
curl -I http://192.168.1.11:30080

# 8. Test HTTP Apache
curl -I http://192.168.1.11:30081

# 9. Test MariaDB
sudo k3s kubectl run -it --rm mysql-client \
  --image=mysql:latest \
  --command -- \
  mysql -h mariadb-service -u root -prootpass -e "SHOW DATABASES;"
```

**Résultat attendu** :
- ✅ 3 Deployments créés
- ✅ 3 Pods en `Running`
- ✅ 3 Services créés
- ✅ Curl Nginx répond 200
- ✅ Curl Apache répond 200
- ✅ MySQL client se connecte et voit les BD

---

## 📝 Dépannage JOB 03

| Symptôme | Cause | Solution |
|----------|-------|----------|
| `ImagePullBackOff` | Image non disponible | Vérifier la syntaxe du manifest (image:) |
| `CrashLoopBackOff` | Erreur au démarrage du conteneur | `kubectl logs <pod>` pour voir l'erreur |
| `Pending` | Pas de ressources / nœud pas ready | `kubectl describe pod <nom>` |
| Service injoignable (30080) | NodePort pas bien configuré | Vérifier nodePort et selector dans le Service |
| MariaDB très lent au démarrage | C'est normal | Attendre 1-2 minutes, c'est lourd |

---

## 🗂️ Organisation des Manifests

Pour garder les choses organisées, stocker tous les manifests dans un répertoire :

```bash
manifests/
├── nginx-deployment.yaml
├── apache-deployment.yaml
└── mariadb-deployment.yaml
```

Appliquer tous les manifests à la fois :

```bash
sudo k3s kubectl apply -f manifests/
```

---

## 🔄 Mettre à Jour une Application

Si vous changez l'image (par exemple, passer à `nginx:1.25`) :

```bash
# Éditer le manifest
nano nginx-deployment.yaml  # Changer image: nginx:latest → nginx:1.25

# Réappliquer
sudo k3s kubectl apply -f nginx-deployment.yaml

# K3S mettra à jour automatiquement les pods
sudo k3s kubectl get pods | grep nginx
```

---

## 🧹 Supprimer une Application

```bash
# Supprimer tout ce qui est relié
sudo k3s kubectl delete -f nginx-deployment.yaml

# Ou supprimer individuellement
sudo k3s kubectl delete deployment nginx
sudo k3s kubectl delete service nginx-service
```

---

## ✅ Prêt pour JOB 04 ?

```bash
# Vérifier que les 3 apps sont prêtes
sudo k3s kubectl get pods | grep -E 'nginx|apache|mariadb'

# Doit afficher 3 pods en Running
```

→ **Suivant** : [JOB 04 — Haute Disponibilité (Replicas & Self-Healing)](./JOB_04_ha.md)

---

**Ressources**
- Kubernetes Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services : https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMaps : https://kubernetes.io/docs/concepts/configuration/configmap/

**Notes de l'étudiant** :
```
[À remplir lors de la réalisation]
- Nginx déployé: ☐  Port accessible: ☐
- Apache déployé: ☐  Port accessible: ☐
- MariaDB déployé: ☐  Connexion OK: ☐
- Problèmes: ___
```
