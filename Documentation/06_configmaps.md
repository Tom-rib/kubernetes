# 06 - ConfigMaps et Gestion de Configuration (Job 06)

## 🎯 Objectif
Utiliser les **ConfigMaps** pour gérer les configurations d'applications sans modifier les images Docker.

## 📋 Table des matières
1. [Concepts](#concepts)
2. [Créer une ConfigMap](#créer-une-configmap)
3. [Utiliser la ConfigMap](#utiliser-la-configmap)
4. [Exemple : Nginx avec ConfigMap](#exemple--nginx-avec-configmap)

---

## 💡 Concepts

### ConfigMap
- Objet Kubernetes stockant des données non-confidentielles
- Format : clé-valeur
- Cas d'usage : fichiers de config, variables d'environnement, scripts

### Avantages
- ✅ Séparer config du code
- ✅ Réutilisable entre pods
- ✅ Modifier sans redéployer l'image

### Format
```
ConfigMap
├─ key1: value1
├─ key2: value2
└─ config.conf: [contenu du fichier]
```

---

## 📝 Créer une ConfigMap

### Méthode 1 : Depuis une commande

```bash
# Créer une ConfigMap simple
kubectl create configmap app-config --from-literal=APP_NAME=MyApp --from-literal=DEBUG=true

# Vérifier
kubectl get configmaps
kubectl describe configmap app-config
```

### Méthode 2 : Depuis un fichier

```bash
# Créer un fichier de config
cat > app.conf << 'EOF'
APP_NAME=MyApp
DEBUG=true
LOG_LEVEL=INFO
DATABASE_URL=mysql://localhost:3306/myapp
EOF

# Créer la ConfigMap
kubectl create configmap app-config --from-file=app.conf

# Vérifier
kubectl describe configmap app-config
```

### Méthode 3 : Depuis un fichier YAML (recommandé)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_NAME: "MyApp"
  DEBUG: "true"
  LOG_LEVEL: "INFO"
  app.conf: |
    # Configuration file
    server.port=8080
    server.host=0.0.0.0
    database.url=mysql://localhost:3306
```

Créer et appliquer :

```bash
kubectl apply -f configmap.yaml

# Vérifier
kubectl get configmap app-config -o yaml
```

---

## 🚀 Utiliser la ConfigMap

### Méthode 1 : Variables d'environnement

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
        env:
        # Depuis ConfigMap
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_NAME
        - name: DEBUG
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DEBUG
        # Ou variables directes
        - name: PORT
          value: "8080"
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
        # Monter la ConfigMap comme un fichier
        - name: config-volume
          mountPath: /etc/config
      volumes:
      # Utiliser la ConfigMap comme source
      - name: config-volume
        configMap:
          name: app-config
          items:
          - key: app.conf
            path: app.conf
```

---

## 💻 Exemple : Nginx avec ConfigMap

### Étape 1 : Créer une configuration Nginx

Fichier `nginx.conf` :

```nginx
server {
  listen 80;
  server_name _;

  root /usr/share/nginx/html;
  index index.html;

  location / {
    try_files $uri $uri/ =404;
  }

  location /api {
    return 200 "API Configuration: ${API_URL}";
  }
}
```

### Étape 2 : Créer la ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
      listen 80;
      server_name _;
      
      root /usr/share/nginx/html;
      index index.html;
      
      location / {
        try_files $uri $uri/ =404;
      }
    }
  APP_ENV: "production"
  LOG_LEVEL: "info"
```

### Étape 3 : Déployer Nginx avec ConfigMap

```yaml
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
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: APP_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: LOG_LEVEL
        volumeMounts:
        - name: nginx-config-volume
          mountPath: /etc/nginx/conf.d/
      volumes:
      - name: nginx-config-volume
        configMap:
          name: nginx-config
          items:
          - key: default.conf
            path: default.conf
```

---

## ✅ Vérification

### Check 1 : ConfigMap créée

```bash
kubectl get configmaps
kubectl describe configmap nginx-config
```

### Check 2 : Variables d'environnement

```bash
# Vérifier dans le pod
kubectl exec [POD] -- env | grep APP_ENV
```

### Check 3 : Fichiers montés

```bash
# Vérifier le fichier
kubectl exec [POD] -- cat /etc/nginx/conf.d/default.conf
```

### Check 4 : Modification de la ConfigMap

```bash
# Modifier la ConfigMap
kubectl edit configmap nginx-config
# Changer APP_ENV = "development"

# Redéployer les pods (changement pas automatique)
kubectl rollout restart deployment/nginx-deployment

# Vérifier
kubectl exec [POD] -- env | grep APP_ENV
```

---

## 📋 Exemple complet

Fichier `nginx-configmap-complete.yaml` :

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
      listen 80;
      server_name _;
      root /usr/share/nginx/html;
      index index.html;
      
      location / {
        try_files $uri $uri/ =404;
      }
    }
  APP_ENV: "production"
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
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: APP_ENV
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d/
      volumes:
      - name: config
        configMap:
          name: nginx-config
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

---

## 📝 Journal de bord

```
Date : [date]
ConfigMap créée :
  - nginx-config : [OK/NOK]
  - app-config : [OK/NOK]

Variables d'environnement :
  - Accessibles dans le pod : [OK/NOK]

Fichiers de config :
  - Montés correctement : [OK/NOK]
  - Contenu correct : [OK/NOK]

Modifications :
  - ConfigMap modifiée : [OK/NOK]
  - Pods mis à jour : [OK/NOK]
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ ConfigMaps créées
- ✓ Variables d'environnement utilisées
- ✓ Fichiers de config montés

**Passez à : `07_secrets.md`** pour gérer les données sensibles.

---

**✅ Les ConfigMaps sont configurées ! Passons aux Secrets.**
