# JOB 09 — Helm & Industrialisation

**Objectif** : Empaqueter et déployer une application complète via Helm. Maîtriser install, upgrade, rollback.

**Durée estimée** : 25 minutes  
**Prérequis** : JOB 08 complété

---

## 🎯 Helm : Concepts

| Objet | Rôle |
|-------|------|
| **Chart** | Paquet d'une application (templates + values) |
| **Release** | Instance installée d'un chart |
| **Values** | Paramètres personnalisables (values.yaml) |
| **Template** | Manifeste K8s avec variables {{ }} |
| **Repository** | Dépôt de charts (public ou privé) |

---

## 🚀 Étape 1 : Installer Helm

```bash
# Télécharger Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Vérifier
helm version

# Ajouter un dépôt public
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Lister les repos
helm repo list
```

---

## 🚀 Étape 2 : Créer un Chart Personnalisé

### Créer la structure

```bash
helm create k3s-app
cd k3s-app
```

Cela génère :

```
k3s-app/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── _helpers.tpl
└── charts/
```

### Éditer `Chart.yaml`

```yaml
apiVersion: v2
name: k3s-app
description: Application K3S multi-composants
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - k3s
  - nginx
  - apache
  - mariadb
maintainers:
  - name: Étudiant
    email: etudiant@example.com
```

### Éditer `values.yaml`

```yaml
# Nginx
nginx:
  enabled: true
  replicaCount: 3
  image:
    repository: nginx
    tag: latest
  port: 80
  nodePort: 30080
  resources:
    requests:
      cpu: 100m
      memory: 128Mi

# Apache
apache:
  enabled: true
  replicaCount: 2
  image:
    repository: httpd
    tag: latest
  port: 80
  nodePort: 30081
  resources:
    requests:
      cpu: 100m
      memory: 128Mi

# MariaDB
mariadb:
  enabled: true
  replicaCount: 1
  image:
    repository: mariadb
    tag: latest
  port: 3306
  rootPassword: "SecurePass123!"
  resources:
    requests:
      cpu: 250m
      memory: 512Mi

# Global
global:
  environment: production
```

---

## 🔧 Étape 3 : Créer les Templates Helm

### `templates/deployment.yaml`

```yaml
{{- if .Values.nginx.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "k3s-app.fullname" . }}-nginx
  labels:
    {{- include "k3s-app.labels" . | nindent 4 }}
    app: nginx
spec:
  replicas: {{ .Values.nginx.replicaCount }}
  selector:
    matchLabels:
      {{- include "k3s-app.selectorLabels" . | nindent 6 }}
      app: nginx
  template:
    metadata:
      labels:
        {{- include "k3s-app.selectorLabels" . | nindent 8 }}
        app: nginx
    spec:
      containers:
      - name: nginx
        image: "{{ .Values.nginx.image.repository }}:{{ .Values.nginx.image.tag }}"
        ports:
        - containerPort: {{ .Values.nginx.port }}
        resources:
          {{- toYaml .Values.nginx.resources | nindent 12 }}
{{- end }}
---
{{- if .Values.apache.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "k3s-app.fullname" . }}-apache
spec:
  replicas: {{ .Values.apache.replicaCount }}
  # ... similaire à Nginx ...
{{- end }}
```

### `templates/service.yaml`

```yaml
{{- if .Values.nginx.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "k3s-app.fullname" . }}-nginx
spec:
  type: NodePort
  selector:
    {{- include "k3s-app.selectorLabels" . | nindent 4 }}
    app: nginx
  ports:
  - port: {{ .Values.nginx.port }}
    targetPort: {{ .Values.nginx.port }}
    nodePort: {{ .Values.nginx.nodePort }}
{{- end }}
```

---

## 🚀 Étape 4 : Installer le Chart

### Valider le chart

```bash
helm lint k3s-app/
# Doit afficher: 1 chart(s) linted, 0 error(s)
```

### Installer en dry-run (test)

```bash
helm install k3s-release k3s-app/ --dry-run --debug

# Affiche les manifests sans les appliquer
```

### Installer pour de vrai

```bash
helm install k3s-release k3s-app/

# Vérifier
helm list
kubectl get all
```

---

## 🔄 Étape 5 : Mettre à Jour le Chart (Upgrade)

### Changer une valeur

```bash
# Augmenter les replicas Nginx
helm upgrade k3s-release k3s-app/ \
  --set nginx.replicaCount=5

# K3S mettra à jour progressivement
kubectl get pods | grep nginx
# Doit afficher 5 pods
```

### Voir l'historique des releases

```bash
helm history k3s-release

# Output:
# REVISION  UPDATED            STATUS      CHART        DESCRIPTION
# 1         ...                DEPLOYED    k3s-app-1.0  Install complete
# 2         ...                DEPLOYED    k3s-app-1.0  Upgrade complete
```

---

## ↩️ Étape 6 : Rollback

### Revenir à la version précédente

```bash
# Revenir à la révision 1
helm rollback k3s-release 1

# Vérifier
helm list
kubectl get pods | grep nginx
# Doit afficher 3 pods à nouveau
```

---

## 🧪 Étape 7 : Installer un Chart Public

### Chercher un chart

```bash
helm search repo bitnami | grep -i nginx
```

### Installer un chart public

```bash
# Installer Nginx depuis Bitnami
helm install my-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=NodePort \
  --set service.nodePort=30090

# Vérifier
helm list
kubectl get pods
curl http://192.168.1.11:30090
```

### Personnaliser avec un fichier values

```bash
# Créer my-values.yaml
cat > my-values.yaml << EOF
replicaCount: 5
image:
  tag: "1.25"
service:
  type: NodePort
  nodePort: 30090
EOF

# Installer avec les paramètres personnalisés
helm install my-nginx bitnami/nginx -f my-values.yaml
```

---

## 📊 Vérification Complète (JOB 09)

```bash
# 1. Helm installé?
helm version

# 2. Charts disponibles?
helm search repo bitnami | head -5

# 3. Releases installées?
helm list -a

# 4. Vérifier un chart personnel
helm get values k3s-release

# 5. Voir les manifests générés
helm get manifest k3s-release | head -30

# 6. Vérifier l'historique
helm history k3s-release

# 7. Pods en place?
kubectl get pods | grep -E 'nginx|apache|mariadb'
```

---

## 🧹 Étape 8 : Supprimer une Release

```bash
# Supprimer la release
helm uninstall k3s-release

# Vérifier
helm list
kubectl get pods | grep -E 'nginx|apache'
# Doit être vide
```

---

## 🏆 Étape 9 : Package et Publish (Bonus)

### Packager le chart

```bash
helm package k3s-app/

# Génère k3s-app-1.0.0.tgz
```

### Installer depuis le package

```bash
helm install k3s-release k3s-app-1.0.0.tgz
```

### Publier dans un dépôt (avancé)

Voir la documentation Helm pour HeartBeat ou Artifact Hub.

---

## 📝 Dépannage JOB 09

| Problème | Solution |
|----------|----------|
| `helm: not found` | Réinstaller Helm (voir Étape 1) |
| Template error | Vérifier la syntaxe Helm (`helm lint`) |
| Values pas appliquées | Vérifier les indentations YAML |
| Rollback échoue | Révision invalide → `helm history` |

---

## ✅ Validation Finale

```bash
# Tous les JOBs complétés?
helm list
kubectl get nodes
kubectl get pods -A | wc -l
# Doit afficher > 20 pods
```

→ **Prêt pour la présentation!**

---

## 📚 Ressources

- Helm Docs : https://helm.sh/docs/
- Helm Chart Template Guide : https://helm.sh/docs/chart_template_guide/
- Artifact Hub : https://artifacthub.io/

**Notes de l'étudiant** :
```
- Helm installé: ☐
- Chart personnel créé: ☐
- Install + Upgrade + Rollback testés: ☐
- Chart public installé: ☐
- Release supprimée: ☐
```
