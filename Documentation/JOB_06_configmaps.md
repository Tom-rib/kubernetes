# JOB 06 — ConfigMaps (Configuration Externalisée)

**Objectif** : Externaliser la configuration des applications via ConfigMaps (variables, fichiers).

**Durée estimée** : 15 minutes  
**Prérequis** : JOB 05 complété

---

## 🎯 Concepts

**ConfigMap** = clés/valeurs ou fichiers de config externalisés du code.

**Avantages** :
- ✅ Configuration séparée du Deployment
- ✅ Réutilisable par plusieurs pods
- ✅ Mutable sans redéployer

---

## 🚀 Étape 1 : ConfigMap pour Nginx

### Créer `nginx-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  # Clés simples
  WORKER_PROCESSES: "4"
  WORKER_CONNECTIONS: "1024"
  
  # Fichier complet
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;
    
    events {
      worker_connections 1024;
    }
    
    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;
      
      log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
      
      access_log /var/log/nginx/access.log main;
      
      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;
      keepalive_timeout 65;
      types_hash_max_size 2048;
      
      server {
        listen 80;
        server_name _;
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
      }
    }
```

### Appliquer la ConfigMap

```bash
sudo k3s kubectl apply -f nginx-configmap.yaml

# Vérifier
sudo k3s kubectl get configmap
sudo k3s kubectl describe configmap nginx-config
```

### Utiliser la ConfigMap dans Nginx Deployment

Éditer `nginx-deployment.yaml` :

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        # ... reste ...
        env:
        - name: WORKER_PROCESSES
          valueFrom:
            configMapKeyRef:
              name: nginx-config
              key: WORKER_PROCESSES
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx
      volumes:
      - name: nginx-conf
        configMap:
          name: nginx-config
```

Réappliquer :

```bash
sudo k3s kubectl apply -f nginx-deployment.yaml
```

---

## 🚀 Étape 2 : ConfigMap pour Apache

### Créer `apache-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: apache-config
data:
  httpd.conf: |
    ServerRoot "/usr/local/apache2"
    Listen 80
    
    LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
    
    <IfModule mpm_prefork_module>
      StartServers 10
      MinSpareServers 10
      MaxSpareServers 20
      MaxRequestWorkers 256
      MaxConnectionsPerChild 0
    </IfModule>
    
    DocumentRoot "/usr/local/apache2/htdocs"
    
    <Directory />
      AllowOverride none
      Require all denied
    </Directory>
    
    <Directory "/usr/local/apache2/htdocs">
      AllowOverride None
      Require all granted
    </Directory>
    
    ErrorLog logs/error_log
    LogLevel warn
    CustomLog logs/access_log combined
```

Appliquer et utiliser :

```bash
sudo k3s kubectl apply -f apache-configmap.yaml

# Éditer apache-deployment.yaml pour monter le fichier
# volumeMounts:
# - name: apache-conf
#   mountPath: /usr/local/apache2/conf
# volumes:
# - name: apache-conf
#   configMap:
#     name: apache-config
```

---

## 🧪 Étape 3 : Test de ConfigMap

### Vérifier le montage

```bash
# Vérifier que le fichier existe dans le pod Nginx
sudo k3s kubectl exec -it deployment/nginx -- cat /etc/nginx/nginx.conf

# Doit afficher la config complète
```

### Mettre à jour la ConfigMap (pas de redéploiement)

```bash
# Éditer directement
sudo k3s kubectl edit configmap nginx-config

# Les pods ne se mettront PAS à jour automatiquement!
# Forcer un redéploiement:
sudo k3s kubectl rollout restart deployment/nginx
```

---

## 📊 Vérification Complète (JOB 06)

```bash
# 1. ConfigMaps créées
sudo k3s kubectl get configmap

# 2. Vérifier le contenu
sudo k3s kubectl get configmap nginx-config -o yaml

# 3. Vérifier le montage dans le pod
sudo k3s kubectl exec -it deployment/nginx -- ls -la /etc/nginx/

# 4. Vérifier les variables d'env
sudo k3s kubectl exec -it deployment/nginx -- env | grep WORKER
```

---

## 📝 Dépannage JOB 06

| Problème | Solution |
|----------|----------|
| Pod ne démarre pas après apply | Configmap mal formatée → `kubectl describe pod` |
| ConfigMap montée mais fichier vide | Clé mal nommée dans le spec |
| Changement de ConfigMap pas appliqué | Redémarrer le pod: `rollout restart` |

---

## 🔐 Note Importante

⚠️ **ConfigMaps ne sont PAS chiffrées** ! Ne pas y mettre de secrets (mots de passe, clés).

→ Voir JOB 07 pour les Secrets.

---

## ✅ Prêt pour JOB 07 ?

```bash
sudo k3s kubectl get configmap | grep -E 'nginx|apache'
# Doit afficher 2 configmaps
```

→ **Suivant** : [JOB 07 — Secrets (Données Sensibles)](./JOB_07_secrets.md)

**Notes de l'étudiant** :
```
- ConfigMap Nginx créée: ☐
- ConfigMap Apache créée: ☐
- Montage vérifié: ☐
```
