# 07 - Secrets et Données Sensibles (Job 07)

## 🎯 Objectif
Gérer les données sensibles (mots de passe, clés API, certificats) avec les **Secrets** de Kubernetes.

## 📋 Table des matières
1. [Concepts](#concepts)
2. [Créer un Secret](#créer-un-secret)
3. [Utiliser un Secret](#utiliser-un-secret)
4. [Exemple : MariaDB avec Secrets](#exemple--mariadb-avec-secrets)

---

## 💡 Concepts

### Secret
- Objet Kubernetes pour données sensibles
- Encodé en base64 (⚠️ pas chiffré par défaut)
- Cas d'usage : mots de passe, tokens, certificats

### Types de Secrets
| Type | Utilisation |
|------|-----------|
| **Opaque** | Données génériques (par défaut) |
| **docker-registry** | Credentials Docker |
| **basic-auth** | Authentification HTTP |
| **ssh-auth** | Clés SSH |
| **tls** | Certificats TLS |

### Avantages
- ✅ Séparer secrets du code
- ✅ Rotation facile
- ✅ Base64 encodé (protection basique)
- ⚠️ Pas chiffré par défaut (encryption à configurer)

---

## 📝 Créer un Secret

### Méthode 1 : Depuis une commande

```bash
# Créer un Secret simple
kubectl create secret generic db-credentials \
  --from-literal=username=appuser \
  --from-literal=password=supersecret

# Vérifier
kubectl describe secret db-credentials
```

### Méthode 2 : Depuis un fichier

```bash
# Créer un fichier avec la password
echo "supersecret" > password.txt

# Créer le Secret
kubectl create secret generic db-credentials \
  --from-file=password=password.txt \
  --from-literal=username=appuser

# Nettoyer
rm password.txt
```

### Méthode 3 : Depuis un fichier YAML (recommandé)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  # Base64 encoded
  username: YXBwdXNlcg==        # "appuser" en base64
  password: c3VwZXJzZWNyZXQ==  # "supersecret" en base64
```

**Encoder en base64** :

```bash
echo -n "appuser" | base64
# YXBwdXNlcg==

echo -n "supersecret" | base64
# c3VwZXJzZWNyZXQ==

# Décoder
echo "YXBwdXNlcg==" | base64 -d
# appuser
```

Ou utiliser `stringData` (pas besoin de base64) :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: appuser
  password: supersecret
```

---

## 🚀 Utiliser un Secret

### Méthode 1 : Variables d'environnement

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
spec:
  template:
    spec:
      containers:
      - name: mariadb
        image: mariadb:latest
        env:
        # Depuis Secret
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        # Ou directement
        - name: MYSQL_ROOT_PASSWORD
          value: "root"
```

### Méthode 2 : Fichiers montés

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: secrets-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: secrets-volume
        secret:
          secretName: db-credentials
```

Accès dans le pod :

```bash
# Le Secret est montée comme fichiers
cat /etc/secrets/username    # appuser
cat /etc/secrets/password    # supersecret
```

---

## 💻 Exemple : MariaDB avec Secrets

### Étape 1 : Créer les Secrets

Fichier `mariadb-secrets.yaml` :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-credentials
type: Opaque
stringData:
  mysql-root-password: RootSecurePass123!
  mysql-user: appuser
  mysql-password: AppSecurePass456!
---
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-config
type: Opaque
stringData:
  my.cnf: |
    [mysqld]
    bind-address=0.0.0.0
    skip-name-resolve
    max_connections=1000
```

### Étape 2 : Déployer MariaDB avec Secrets

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
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
        # Variables depuis Secrets
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-root-password
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-password
        - name: MYSQL_DATABASE
          value: "myapp"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        - name: mysql-config
          mountPath: /etc/mysql/conf.d
          readOnly: true
      volumes:
      - name: mysql-data
        persistentVolumeClaim:
          claimName: mariadb-pvc
      - name: mysql-config
        secret:
          secretName: mariadb-config
          items:
          - key: my.cnf
            path: my.cnf
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

### Étape 3 : Appliquer les Secrets

```bash
kubectl apply -f mariadb-secrets.yaml

# Vérifier
kubectl get secrets
kubectl describe secret mariadb-credentials
```

### Étape 4 : Vérifier les variables d'environnement

```bash
# Exécuter la commande MariaDB
kubectl exec -it [MARIADB_POD] -- mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 'OK';"

# Ou
kubectl exec -it [MARIADB_POD] -- env | grep MYSQL
```

---

## ✅ Vérification

### Check 1 : Secrets créés

```bash
kubectl get secrets
# Expected: mariadb-credentials, mariadb-config

kubectl describe secret mariadb-credentials
```

### Check 2 : Variables d'environnement

```bash
# Vérifier dans le pod
kubectl exec [POD] -- printenv | grep MYSQL

# Ou directement
kubectl exec [POD] -- echo $MYSQL_USER
```

### Check 3 : Fichiers de configuration

```bash
# Vérifier le fichier montée
kubectl exec [POD] -- cat /etc/mysql/conf.d/my.cnf
```

### Check 4 : Authentification MariaDB

```bash
# Se connecter avec les credentials
kubectl exec [POD] -- mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;"
```

---

## 🔐 Sécurité des Secrets

### ⚠️ Attention : Base64 ≠ Chiffrement

Base64 c'est juste de l'encodage, pas du chiffrement !

```bash
# Quelqu'un peut décoder
kubectl get secret mariadb-credentials -o jsonpath='{.data.mysql-password}' | base64 -d
# Affiche : AppSecurePass456!
```

### Solutions de sécurité

1. **RBAC** : Restreindre l'accès aux Secrets (voir Job 08)
2. **Encryption at rest** : Chiffrer les Secrets en base de données etcd
3. **External Secrets** : Utiliser Vault ou AWS Secrets Manager
4. **Network Policy** : Restreindre l'accès au cluster

### Voir les Secrets en YAML

```bash
# Voir le Secret en YAML
kubectl get secret mariadb-credentials -o yaml

# Voir juste les données encodées
kubectl get secret mariadb-credentials -o jsonpath='{.data}'
```

---

## 📋 Fichier complet

Fichier `mariadb-complete-secrets.yaml` :

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-credentials
type: Opaque
stringData:
  mysql-root-password: RootSecurePass123!
  mysql-user: appuser
  mysql-password: AppSecurePass456!
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /var/lib/rancher/k3s/server/local-path-provisioner/mysql-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
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
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-root-password
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: mysql-password
        - name: MYSQL_DATABASE
          value: "myapp"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-data
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

---

## 📝 Journal de bord

```
Date : [date]
Secrets créés :
  - mariadb-credentials : [OK/NOK]
  - mariadb-config : [OK/NOK]

Variables d'environnement :
  - MYSQL_USER : [OK/NOK]
  - MYSQL_PASSWORD : [OK/NOK]

Fichiers de config :
  - my.cnf montée : [OK/NOK]

Authentification :
  - MariaDB avec Secret password : [OK/NOK]
  - Données persistantes : [OK/NOK]
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ Secrets créés pour MariaDB
- ✓ Variables d'environnement utilisées
- ✓ Authentification fonctionnelle

**Passez à : `08_rbac.md`** pour mettre en place le contrôle d'accès (RBAC).

---

**✅ Les Secrets sont configurés ! Passons à RBAC.**
