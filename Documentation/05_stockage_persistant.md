# 05 - Stockage Persistant (Job 05)

## 🎯 Objectif
Configurer le **stockage persistant** pour que les données survivent au redémarrage des pods. Appliquer cela à **Nginx** et **MariaDB**.

## 📋 Table des matières
1. [Concepts de stockage](#concepts-de-stockage)
2. [Storag pour Nginx](#stockage-pour-nginx)
3. [Stockage pour MariaDB](#stockage-pour-mariadb)
4. [Vérification](#vérification)
5. [Gestion des volumes](#gestion-des-volumes)

---

## 💡 Concepts de stockage

### PersistentVolume (PV)
- Volume physique sur le cluster
- Indépendant des pods
- Exemple : `/var/data/vol1`

### PersistentVolumeClaim (PVC)
- Demande de stockage par un pod
- Réserve de l'espace du PV
- Exemple : "Je veux 10 GB de stockage"

### StorageClass (SC)
- Profil de stockage (fast, slow, replicated)
- Provisionne automatiquement les PV

### Cycle de vie
```
1. Admin crée PersistentVolume (PV)
2. Utilisateur crée PersistentVolumeClaim (PVC)
3. Kubernetes associe PVC → PV
4. Pod monte le PVC en tant que volume
5. Données persistent après redémarrage du pod
```

---

## 📂 Stockage pour Nginx

### Cas d'usage
Nginx stocke ses fichiers HTML dans `/usr/share/nginx/html`.
Nous allons créer un volume persistant pour ces fichiers.

### Étape 1 : Créer le répertoire sur le master

```bash
# Sur kubes-01, créer le répertoire
sudo mkdir -p /var/lib/rancher/k3s/server/local-path-provisioner/nginx-data
sudo chmod 777 /var/lib/rancher/k3s/server/local-path-provisioner/nginx-data

# Y ajouter un fichier HTML de test
sudo bash -c 'cat > /var/lib/rancher/k3s/server/local-path-provisioner/nginx-data/index.html << "EOF"
<!DOCTYPE html>
<html>
<head>
  <title>Kubernetes Nginx</title>
</head>
<body>
  <h1>✅ Nginx fonctionne avec stockage persistant</h1>
  <p>Pod: $(hostname)</p>
  <p>Date: $(date)</p>
</body>
</html>
EOF'
```

### Étape 2 : Créer le manifeste Nginx avec volume

Fichier `nginx-storage.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  storageClassName: local-path
  hostPath:
    path: /var/lib/rancher/k3s/server/local-path-provisioner/nginx-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - kubes-01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
---
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
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-storage
        persistentVolumeClaim:
          claimName: nginx-pvc
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
```

### Étape 3 : Appliquer le manifeste

```bash
kubectl apply -f nginx-storage.yaml

# Vérifier
kubectl get pv
# Expected: nginx-pv avec STATUS = Bound

kubectl get pvc
# Expected: nginx-pvc avec STATUS = Bound

kubectl get pods -l app=nginx -o wide
```

### Étape 4 : Tester le stockage persistant

```bash
# Accédez à Nginx
curl http://localhost
# Devrait afficher le HTML du volume

# Modifier le contenu
kubectl exec -it $(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- bash

# Depuis le pod:
echo "Contenu modifié" > /usr/share/nginx/html/test.txt
exit

# Vérifier depuis Nginx
curl http://localhost/test.txt
# Devrait afficher "Contenu modifié"

# Supprimer le pod et vérifier que les données persistent
kubectl delete pod [POD_NAME]

# Le pod est relancé
kubectl get pods -l app=nginx

# Vérifier que le fichier existe toujours
curl http://localhost/test.txt
# Devrait toujours afficher "Contenu modifié"
```

---

## 🗄️ Stockage pour MariaDB

### Cas d'usage
MariaDB stocke les données dans `/var/lib/mysql`.
Sans volume persistant, les données sont perdues à chaque redémarrage.

### Étape 1 : Préparer le répertoire pour MariaDB

```bash
# Sur kubes-01, créer le répertoire
sudo mkdir -p /var/lib/rancher/k3s/server/local-path-provisioner/mysql-data
sudo chmod 777 /var/lib/rancher/k3s/server/local-path-provisioner/mysql-data
```

### Étape 2 : Créer le manifeste MariaDB avec volume

Fichier `mariadb-storage.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  hostPath:
    path: /var/lib/rancher/k3s/server/local-path-provisioner/mysql-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - kubes-01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
---
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
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mariadb-pvc
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

### Étape 3 : Appliquer le manifeste

```bash
kubectl apply -f mariadb-storage.yaml

# Vérifier
kubectl get pv
kubectl get pvc
kubectl get pods -l app=mariadb
```

### Étape 4 : Tester la persistance des données MariaDB

```bash
# Créer une base de données et insérer des données
kubectl exec -it $(kubectl get pods -l app=mariadb -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -proot << 'EOF'
CREATE DATABASE IF NOT EXISTS myapp;
CREATE TABLE myapp.test (id INT, name VARCHAR(100));
INSERT INTO myapp.test VALUES (1, 'Test Data');
SELECT * FROM myapp.test;
EOF

# Supprimer le pod
kubectl delete pod $(kubectl get pods -l app=mariadb -o jsonpath='{.items[0].metadata.name}')

# Attendre que le pod soit relancé
kubectl get pods -l app=mariadb --watch

# Vérifier que les données sont toujours là
kubectl exec -it $(kubectl get pods -l app=mariadb -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -proot -e "SELECT * FROM myapp.test;"

# Expected output:
# | 1 | Test Data |
```

---

## ✅ Vérification

### Check 1 : Tous les PV et PVC sont créés

```bash
kubectl get pv
# Expected:
# NAME         CAPACITY   ACCESS MODES   ...   STATUS
# nginx-pv     1Gi        RWX            ...   Bound
# mariadb-pv   5Gi        RWO            ...   Bound

kubectl get pvc
# Expected:
# NAME           STATUS   VOLUME       ...
# nginx-pvc      Bound    nginx-pv     ...
# mariadb-pvc    Bound    mariadb-pv   ...
```

### Check 2 : Les volumes sont montés

```bash
# Vérifier les montages dans Nginx
kubectl exec -it [NGINX_POD] -- df -h | grep nginx-storage

# Vérifier les montages dans MariaDB
kubectl exec -it [MYSQL_POD] -- df -h | grep mysql-storage
```

### Check 3 : Les données persistent

```bash
# Pour Nginx
curl http://localhost/test.txt

# Pour MariaDB
kubectl exec [MYSQL_POD] -- mysql -uroot -proot -e "SELECT * FROM myapp.test;"
```

---

## 📋 Gestion des volumes

### Voir les volumes

```bash
# Voir les PV
kubectl get pv
kubectl describe pv nginx-pv

# Voir les PVC
kubectl get pvc
kubectl describe pvc nginx-pvc

# Voir l'utilisation d'espace
kubectl exec [POD] -- df -h
```

### Supprimer les volumes

```bash
# Supprimer une PVC
kubectl delete pvc nginx-pvc

# ⚠️ Cela supprime aussi les données !

# Supprimer un PV
kubectl delete pv nginx-pv
```

### Augmenter la taille d'un volume

```bash
# Éditer la PVC
kubectl edit pvc nginx-pvc

# Changer "storage: 1Gi" en "storage: 2Gi"
# Sauvegarder

# Vérifier (peut prendre du temps)
kubectl describe pvc nginx-pvc
```

---

## 📊 Types d'AccessModes

| Mode | Description | Utilisation |
|------|-------------|-----------|
| **ReadWriteOnce (RWO)** | 1 nœud peut lire/écrire | Databases, applications |
| **ReadOnlyMany (ROX)** | Plusieurs nœuds peuvent lire | Données statiques |
| **ReadWriteMany (RWX)** | Plusieurs nœuds lire/écrire | Partage de fichiers |

---

## ⚠️ Points d'attention

- ⚠️ **Réplicas Nginx** : Avec RWX, tous les replicas partagent le même stockage
- ⚠️ **MariaDB** : Doit avoir 1 seule instance (RWO) pour éviter les corruptions
- ⚠️ **Nœuds** : Le volume est sur kubes-01, attention au placement des pods
- ⚠️ **Sauvegarde** : N'oubliez pas de sauvegarder les répertoires `/var/lib/rancher/...`

---

## 📚 Fichier complet avec tout

Créer `storage-complete.yaml` :

```yaml
---
# NGINX
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  storageClassName: local-path
  hostPath:
    path: /var/lib/rancher/k3s/server/local-path-provisioner/nginx-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-storage
        persistentVolumeClaim:
          claimName: nginx-pvc
---
# ... (similaire pour Apache et MariaDB)
```

---

## 📝 Journal de bord

```
Date : [date]
PV/PVC créés :
  - Nginx : [OK/NOK]
  - MariaDB : [OK/NOK]

Données persistantes :
  - Nginx file survit à redémarrage : [OK/NOK]
  - MariaDB data survit à redémarrage : [OK/NOK]

Observations :
  - [observation 1]
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ PV et PVC créés pour Nginx et MariaDB
- ✓ Données persistent après redémarrage de pods
- ✓ Volumes montés correctement

**Passez à : `06_configmaps.md`** pour gérer les configurations.

---

**✅ Le stockage persistant est configuré ! Passons aux ConfigMaps.**
