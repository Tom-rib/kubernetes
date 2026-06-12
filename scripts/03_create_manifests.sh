#!/bin/bash

# ============================================================
# Script de creation de TOUTES les manifests Kubernetes
# Pour le projet K3S - JOB 02 à JOB 09
# ============================================================

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Dossiers de base
BASE_DIR="/home/kubes1/kubes/manifests"
APPS_DIR="$BASE_DIR/apps"
STORAGE_DIR="$BASE_DIR/storage"
CONFIG_DIR="$BASE_DIR/config"
RBAC_DIR="$BASE_DIR/rbac"
HELM_DIR="$BASE_DIR/helm"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Création des Manifests Kubernetes K3S${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Créer les dossiers
echo -e "${YELLOW}📁 Création des dossiers...${NC}"
mkdir -p "$APPS_DIR"
mkdir -p "$STORAGE_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$RBAC_DIR"
mkdir -p "$HELM_DIR"
echo -e "${GREEN}✅ Dossiers créés${NC}"
echo ""

# ============================================================
# JOB 02 - DEPLOYER LES APPLICATIONS
# ============================================================
echo -e "${YELLOW}📦 Création JOB 02 - Applications...${NC}"

cat > "$APPS_DIR/01-nginx-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
  labels:
    app: nginx
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

cat > "$APPS_DIR/02-nginx-service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
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
    name: http
EOF

cat > "$APPS_DIR/03-apache-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
  namespace: default
  labels:
    app: apache
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
        version: v1
    spec:
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

cat > "$APPS_DIR/04-apache-service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: apache-service
  namespace: default
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
    name: http
EOF

cat > "$APPS_DIR/05-mariadb-deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: default
  labels:
    app: mariadb
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
        version: v1
    spec:
      containers:
      - name: mariadb
        image: mariadb:latest
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: root-password
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: user-password
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: pvc-mariadb
EOF

cat > "$APPS_DIR/06-mariadb-service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
  namespace: default
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
    name: mysql
EOF

echo -e "${GREEN}✅ JOB 02 créé (5 fichiers)${NC}"
echo ""

# ============================================================
# JOB 05 - STOCKAGE PERSISTANT
# ============================================================
echo -e "${YELLOW}💾 Création JOB 05 - Stockage Persistant...${NC}"

cat > "$STORAGE_DIR/01-pvc-nginx.yaml" << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nginx
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
EOF

cat > "$STORAGE_DIR/02-pvc-mariadb.yaml" << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-mariadb
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
EOF

echo -e "${GREEN}✅ JOB 05 créé (2 fichiers)${NC}"
echo ""

# ============================================================
# JOB 06 - CONFIGMAPS
# ============================================================
echo -e "${YELLOW}⚙️  Création JOB 06 - ConfigMaps...${NC}"

cat > "$CONFIG_DIR/01-nginx-configmap.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
  labels:
    app: nginx
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;
    
    events {
      worker_connections 1024;
    }
    
    http {
      sendfile on;
      tcp_nopush on;
      types_hash_max_size 2048;
      include /etc/nginx/mime.types;
      default_type application/octet-stream;
      
      access_log /var/log/nginx/access.log;
      
      server {
        listen 80;
        server_name _;
        
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
        
        location /health {
          access_log off;
          return 200 "healthy\n";
        }
      }
    }
  
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>K3S Nginx Pod</title>
      <style>
        body { font-family: Arial; text-align: center; margin-top: 50px; }
        h1 { color: #336699; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
      </style>
    </head>
    <body>
      <h1>Welcome to Nginx on Kubernetes K3S</h1>
      <div class="info">
        <p><strong>Hostname:</strong> <span id="hostname"></span></p>
        <p><strong>Status:</strong> Running</p>
        <p><strong>Pod:</strong> Healthy</p>
      </div>
      <script>
        document.getElementById('hostname').textContent = window.location.hostname;
      </script>
    </body>
    </html>

  nginx-env.conf: |
    SERVER_NAME=nginx-k3s
    SERVER_ADMIN=admin@example.com
    LOG_LEVEL=warn
EOF

cat > "$CONFIG_DIR/02-apache-configmap.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: apache-config
  namespace: default
  labels:
    app: apache
data:
  SERVER_ADMIN: admin@example.com
  SERVER_NAME: apache-k3s
  LOG_LEVEL: warn
  ENVIRONMENT: production
  
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>K3S Apache Pod</title>
      <style>
        body { font-family: Arial; text-align: center; margin-top: 50px; }
        h1 { color: #cc6633; }
        .info { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
      </style>
    </head>
    <body>
      <h1>Welcome to Apache (httpd) on Kubernetes K3S</h1>
      <div class="info">
        <p><strong>Hostname:</strong> <span id="hostname"></span></p>
        <p><strong>Status:</strong> Running</p>
        <p><strong>Pod:</strong> Healthy</p>
      </div>
      <script>
        document.getElementById('hostname').textContent = window.location.hostname;
      </script>
    </body>
    </html>
EOF

echo -e "${GREEN}✅ JOB 06 créé (2 fichiers)${NC}"
echo ""

# ============================================================
# JOB 07 - SECRETS
# ============================================================
echo -e "${YELLOW}🔐 Création JOB 07 - Secrets...${NC}"

cat > "$CONFIG_DIR/03-mariadb-secret.yaml" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-secret
  namespace: default
  labels:
    app: mariadb
type: Opaque
stringData:
  root-password: RootPassword123!
  user: appuser
  user-password: AppPassword456!
  database: kubernetes_db
EOF

cat > "$CONFIG_DIR/03-registry-secret.yaml" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry-secret
  namespace: default
type: kubernetes.io/dockercfg
data:
  .dockercfg: eyJhdXRocyI6e319  # Base64 encoded empty config
EOF

echo -e "${GREEN}✅ JOB 07 créé (2 fichiers)${NC}"
echo ""

# ============================================================
# JOB 08 - RBAC
# ============================================================
echo -e "${YELLOW}👥 Création JOB 08 - RBAC...${NC}"

cat > "$RBAC_DIR/01-serviceaccount-developer.yaml" << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: default
  labels:
    role: developer
EOF

cat > "$RBAC_DIR/02-role-pod-reader.yaml" << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "pods/logs"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
EOF

cat > "$RBAC_DIR/03-role-app-manager.yaml" << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-manager
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "deployments/scale"]
  verbs: ["get", "list", "watch", "patch", "update"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "delete"]
EOF

cat > "$RBAC_DIR/04-rolebinding-developer.yaml" << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-pod-reader
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
EOF

cat > "$RBAC_DIR/05-rolebinding-app-manager.yaml" << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-app-manager
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-manager
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
EOF

echo -e "${GREEN}✅ JOB 08 créé (5 fichiers)${NC}"
echo ""

# ============================================================
# JOB 09 - HELM
# ============================================================
echo -e "${YELLOW}📦 Création JOB 09 - Helm...${NC}"

cat > "$HELM_DIR/values-nginx.yaml" << 'EOF'
# Helm values pour Nginx
replicaCount: 3

image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 80
  nodePort: 30080

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
EOF

cat > "$HELM_DIR/values-apache.yaml" << 'EOF'
# Helm values pour Apache
replicaCount: 2

image:
  repository: httpd
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 80
  nodePort: 30081

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80
EOF

cat > "$HELM_DIR/values-mariadb.yaml" << 'EOF'
# Helm values pour MariaDB
replicaCount: 1

image:
  repository: mariadb
  tag: latest
  pullPolicy: IfNotPresent

auth:
  rootPassword: RootPassword123!
  username: appuser
  password: AppPassword456!
  database: kubernetes_db

primary:
  persistence:
    enabled: true
    storageClass: local-path
    size: 10Gi

metrics:
  enabled: true

resources:
  limits:
    cpu: 300m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
EOF

echo -e "${GREEN}✅ JOB 09 créé (3 fichiers)${NC}"
echo ""

# ============================================================
# FICHIERS UTILES ADDITIONNELS
# ============================================================
echo -e "${YELLOW}📋 Création de fichiers utiles...${NC}"

cat > "$APPS_DIR/00-README.md" << 'EOF'
# Manifests Kubernetes K3S - Applications

## Structure
- `01-nginx-deployment.yaml` : Deployment Nginx (3 replicas)
- `02-nginx-service.yaml` : Service NodePort pour Nginx
- `03-apache-deployment.yaml` : Deployment Apache (2 replicas)
- `04-apache-service.yaml` : Service NodePort pour Apache
- `05-mariadb-deployment.yaml` : Deployment MariaDB (1 replica)
- `06-mariadb-service.yaml` : Service ClusterIP pour MariaDB

## Déployer TOUTES les applications
```bash
kubectl apply -f .
```

## Déployer application par application
```bash
kubectl apply -f 01-nginx-deployment.yaml
kubectl apply -f 02-nginx-service.yaml
```

## Vérifier
```bash
kubectl get deployments
kubectl get services
kubectl get pods -o wide
```

## Accéder aux services
- Nginx : http://192.168.1.101:30080
- Apache : http://192.168.1.101:30081
- MariaDB : 192.168.1.101:3306 (ClusterIP interne)

## Logs
```bash
kubectl logs <pod-name>
kubectl logs -f <pod-name>
```

## Shell dans un pod
```bash
kubectl exec -it <pod-name> -- bash
```
EOF

cat > "$BASE_DIR/DEPLOY-ALL.sh" << 'EOF'
#!/bin/bash

echo "=========================================="
echo "Déploiement de TOUS les manifests"
echo "=========================================="
echo ""

echo "📦 Déploiement des applications (JOB 02)..."
kubectl apply -f manifests/apps/
echo "✅ Applications déployées"
echo ""

echo "💾 Création du stockage persistant (JOB 05)..."
kubectl apply -f manifests/storage/
echo "✅ Stockage créé"
echo ""

echo "⚙️  Configuration avec ConfigMaps et Secrets (JOB 06-07)..."
kubectl apply -f manifests/config/
echo "✅ Configuration appliquée"
echo ""

echo "👥 Configuration RBAC (JOB 08)..."
kubectl apply -f manifests/rbac/
echo "✅ RBAC configuré"
echo ""

echo ""
echo "=========================================="
echo "Vérifications..."
echo "=========================================="
echo ""

echo "Deployments :"
kubectl get deployments
echo ""

echo "Pods :"
kubectl get pods -o wide
echo ""

echo "Services :"
kubectl get services
echo ""

echo "Stockage :"
kubectl get pvc
echo ""

echo "=========================================="
echo "✅ Déploiement complété !"
echo "=========================================="
EOF

chmod +x "$BASE_DIR/DEPLOY-ALL.sh"

echo -e "${GREEN}✅ Fichiers additionnels créés${NC}"
echo ""

# ============================================================
# AFFICHER LE RÉSUMÉ
# ============================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RÉSUMÉ DE LA CRÉATION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}📁 Dossier principal :${NC}"
echo "   $BASE_DIR"
echo ""

echo -e "${GREEN}📦 JOB 02 - Applications :${NC}"
ls -1 "$APPS_DIR" | grep -E "\.yaml$" | sed 's/^/   /'
echo ""

echo -e "${GREEN}💾 JOB 05 - Stockage :${NC}"
ls -1 "$STORAGE_DIR" | grep -E "\.yaml$" | sed 's/^/   /'
echo ""

echo -e "${GREEN}⚙️  JOB 06-07 - Config & Secrets :${NC}"
ls -1 "$CONFIG_DIR" | grep -E "\.yaml$" | sed 's/^/   /'
echo ""

echo -e "${GREEN}👥 JOB 08 - RBAC :${NC}"
ls -1 "$RBAC_DIR" | grep -E "\.yaml$" | sed 's/^/   /'
echo ""

echo -e "${GREEN}📦 JOB 09 - Helm Values :${NC}"
ls -1 "$HELM_DIR" | grep -E "\.yaml$" | sed 's/^/   /'
echo ""

echo -e "${YELLOW}🚀 COMMANDES PRATIQUES :${NC}"
echo ""
echo "Déployer TOUT :"
echo "   cd $BASE_DIR && bash DEPLOY-ALL.sh"
echo ""
echo "Déployer juste les applications :"
echo "   kubectl apply -f $APPS_DIR/"
echo ""
echo "Déployer juste le stockage :"
echo "   kubectl apply -f $STORAGE_DIR/"
echo ""
echo "Vérifier :"
echo "   kubectl get deployments,pods,services -o wide"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ MANIFESTS CRÉÉES AVEC SUCCÈS !${NC}"
echo -e "${GREEN}========================================${NC}"