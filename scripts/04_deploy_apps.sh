#!/bin/bash
# Script 04 : Deploy applications (Nginx, Apache, MariaDB)
# Usage: ./04_deploy_apps.sh
# Run from master node

set -e

echo "========================================"
echo "Deploying K3S Applications"
echo "========================================"

# Create manifests directory if not exists
mkdir -p manifests/apps

# 1. Deploy Nginx
echo "[*] Deploying Nginx..."
sudo k3s kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
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
EOF

# 2. Deploy Apache
echo "[*] Deploying Apache..."
sudo k3s kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
  labels:
    app: apache
spec:
  replicas: 2
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
EOF

# 3. Deploy MariaDB
echo "[*] Deploying MariaDB..."
sudo k3s kubectl apply -f - << 'EOF'
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
EOF

echo ""
echo "========================================"
echo "✅ Applications deployed!"
echo "========================================"
echo ""
echo "[*] Waiting for pods to start (30 seconds)..."
sleep 30

echo ""
echo "[*] Pod status:"
sudo k3s kubectl get pods -o wide

echo ""
echo "[*] Service status:"
sudo k3s kubectl get svc

echo ""
echo "Test access:"
echo "  Nginx: curl http://localhost:30080"
echo "  Apache: curl http://localhost:30081"
echo "  MariaDB: kubectl exec -it deployment/mariadb -- mysql -u root -prootpass"
