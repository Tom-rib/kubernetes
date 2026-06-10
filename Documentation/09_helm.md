# 09 - Helm et Automatisation des Déploiements (Job 09)

## 🎯 Objectif
Utiliser **Helm** pour packager, templater et déployer des applications Kubernetes de manière réutilisable et versionnée.

## 📋 Table des matières
1. [Qu'est-ce que Helm ?](#quest-ce-que-helm)
2. [Installation](#installation)
3. [Concepts Helm](#concepts-helm)
4. [Créer un Helm Chart](#créer-un-helm-chart)
5. [Déployer avec Helm](#déployer-avec-helm)
6. [Helm Hub et repositories](#helm-hub-et-repositories)

---

## 💡 Qu'est-ce que Helm ?

**Helm** est le "package manager" pour Kubernetes.

### Analogie
```
Kubernetes        →   Docker
Helm Chart        →   Package (apt, npm, pip)
helm install      →   apt install, npm install
values.yaml       →   Configuration du package
```

### Helm résout quoi ?
- ❌ Sans Helm : Gérer 50+ fichiers YAML à la main 😱
- ✅ Avec Helm : 1 commande : `helm install myapp ./mychart`

### Composants
```
Helm
├─ Chart : Template réutilisable
├─ Values : Configuration
├─ Release : Installation d'un chart
└─ Repository : Collection de charts
```

---

## 📦 Installation

### Étape 1 : Installer Helm

```bash
# Télécharger et installer Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Ou avec apt
sudo apt-get install -y helm

# Vérifier
helm version
# Expected: version 3.x
```

### Étape 2 : Vérifier que kubectl fonctionne

```bash
kubectl cluster-info
# Le cluster K3S doit être accessible
```

---

## 🎯 Concepts Helm

### Chart
- Template réutilisable pour une application
- Contient fichiers YAML, images, docs

### Values
- Fichier `values.yaml` avec variables
- Overridables via `--values` ou `--set`

### Release
- Instance déployée d'un chart
- Versionnable, rollbackable

### Repository
- Collection de charts
- Exemple : Bitnami, Stable, ArtifactHub

### Exemple
```
Chart: nginx-chart (template générique)
Values: replicaCount: 3, image: nginx:latest (config)
Release: my-nginx (installation réelle)
```

---

## 🎨 Créer un Helm Chart

### Étape 1 : Créer la structure

```bash
# Créer un nouveau chart
helm create my-app-chart

# Structure créée
my-app-chart/
├── Chart.yaml           # Métadonnées du chart
├── values.yaml          # Valeurs par défaut
├── templates/
│   ├── deployment.yaml  # Deployment K8s
│   ├── service.yaml     # Service K8s
│   ├── configmap.yaml   # ConfigMap
│   └── NOTES.txt        # Message post-install
└── charts/              # Dépendances
```

### Étape 2 : Éditer Chart.yaml

Fichier `Chart.yaml` :

```yaml
apiVersion: v2
name: my-app
description: Application web avec Nginx, Apache et MariaDB
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - nginx
  - apache
  - mariadb
home: https://github.com/example/my-app
source:
  - https://github.com/example/my-app
maintainers:
  - name: John Doe
    email: john@example.com
```

### Étape 3 : Éditer values.yaml

Fichier `values.yaml` :

```yaml
# Valeurs par défaut

# Nginx
nginx:
  enabled: true
  replicaCount: 3
  image:
    repository: nginx
    tag: latest
    pullPolicy: IfNotPresent
  service:
    type: LoadBalancer
    port: 80
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"
      cpu: "200m"

# Apache
apache:
  enabled: true
  replicaCount: 3
  image:
    repository: httpd
    tag: latest
  service:
    type: LoadBalancer
    port: 80
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"

# MariaDB
mariadb:
  enabled: true
  replicaCount: 1
  image:
    repository: mariadb
    tag: latest
  auth:
    rootPassword: root
    user: appuser
    password: apppass
    database: myapp
  service:
    type: ClusterIP
    port: 3306
  persistence:
    enabled: true
    size: 5Gi

# Namespace
namespace: default

# Labels globales
labels:
  app: my-app
  version: v1
```

### Étape 4 : Créer les templates

Template `templates/deployment.yaml` :

```yaml
{{- if .Values.nginx.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}-nginx
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
    app: nginx
spec:
  replicas: {{ .Values.nginx.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
      app: nginx
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
        app: nginx
    spec:
      containers:
      - name: nginx
        image: "{{ .Values.nginx.image.repository }}:{{ .Values.nginx.image.tag }}"
        imagePullPolicy: {{ .Values.nginx.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          {{- toYaml .Values.nginx.resources | nindent 12 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-app.fullname" . }}-nginx
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.nginx.service.type }}
  ports:
  - port: {{ .Values.nginx.service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    {{- include "my-app.selectorLabels" . | nindent 4 }}
    app: nginx
{{- end }}
```

Template `templates/_helpers.tpl` (helpers) :

```
{{/*
Expand the name of the chart.
*/}}
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-app.labels" -}}
helm.sh/chart: {{ include "my-app.chart" . }}
{{ include "my-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

---

## 🚀 Déployer avec Helm

### Méthode 1 : Installation simple

```bash
# Installer le chart
helm install my-release ./my-app-chart

# Voir les releases
helm list

# Voir les ressources créées
kubectl get pods,svc,deployment
```

### Méthode 2 : Avec valeurs personnalisées

```bash
# Installer avec des valeurs custom
helm install my-release ./my-app-chart \
  --values custom-values.yaml

# Ou avec --set
helm install my-release ./my-app-chart \
  --set nginx.replicaCount=5 \
  --set mariadb.auth.rootPassword=SuperSecure123!
```

### Méthode 3 : Mettre à jour une release

```bash
# Mettre à jour (upgrade)
helm upgrade my-release ./my-app-chart \
  --set nginx.replicaCount=10

# Vérifier les changements
kubectl get deployments -l app=nginx
```

### Méthode 4 : Rollback

```bash
# Voir l'historique
helm history my-release

# Revenir à la version précédente
helm rollback my-release 1
# Ou à la version 1
helm rollback my-release 1

# Vérifier
kubectl get pods
```

### Méthode 5 : Supprimer une release

```bash
# Désinstaller
helm uninstall my-release

# Vérifier
kubectl get pods
helm list
```

---

## 📊 Helm Hub et Repositories

### Ajouter un repository

```bash
# Ajouter le repository Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami

# Mettre à jour la cache
helm repo update

# Lister les charts disponibles
helm search repo bitnami | grep nginx
```

### Installer un chart du hub

```bash
# Chercher un chart
helm search repo nginx

# Voir les valeurs disponibles
helm show values bitnami/nginx

# Installer
helm install my-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer

# Vérifier
helm list
kubectl get pods,svc
```

### Utiliser un chart existant

```bash
# Installer MariaDB de Bitnami
helm install my-db bitnami/mariadb \
  --set auth.rootPassword=root \
  --set auth.username=appuser \
  --set auth.password=apppass \
  --set auth.database=myapp

# Vérifier
helm list
helm status my-db
kubectl get pods -l app.kubernetes.io/name=mariadb
```

---

## ✅ Vérification

### Check 1 : Helm installé

```bash
helm version
```

### Check 2 : Chart valide

```bash
# Valider le chart
helm lint ./my-app-chart
# Expected: 0 chart(s) linted, 0 error(s)
```

### Check 3 : Templates correctes

```bash
# Voir les manifests générés
helm template my-release ./my-app-chart | head -50

# Avec valeurs custom
helm template my-release ./my-app-chart \
  --values custom-values.yaml
```

### Check 4 : Installation réussie

```bash
# Statut de la release
helm status my-release

# Voir les notes
helm get notes my-release

# Valeurs utilisées
helm get values my-release
```

---

## 📋 Fichier custom-values.yaml

```yaml
nginx:
  enabled: true
  replicaCount: 5
  image:
    repository: nginx
    tag: 1.25
  resources:
    requests:
      memory: "128Mi"
      cpu: "200m"

apache:
  enabled: true
  replicaCount: 5

mariadb:
  enabled: true
  auth:
    rootPassword: SuperSecure123!
    user: appuser
    password: AppSecure456!
  persistence:
    size: 10Gi
```

Utiliser :

```bash
helm install my-app ./my-app-chart \
  --values custom-values.yaml
```

---

## 📝 Commandes Helm essentielles

```bash
# Lifecycle
helm install RELEASE CHART      # Installer
helm upgrade RELEASE CHART      # Mettre à jour
helm rollback RELEASE [REVISION] # Revenir en arrière
helm uninstall RELEASE           # Désinstaller

# Information
helm list                        # Lister les releases
helm status RELEASE              # Voir le statut
helm history RELEASE             # Historique
helm show values CHART           # Voir les valeurs

# Templating
helm template RELEASE CHART      # Générer les manifests
helm lint CHART                  # Valider le chart

# Repository
helm repo add NAME URL           # Ajouter un repo
helm repo update                 # Mettre à jour
helm search repo TERM            # Chercher un chart
```

---

## 📝 Journal de bord

```
Date : [date]
Helm installé : [OK/NOK]
Chart créé : [OK/NOK]
  - Chart.yaml : [OK/NOK]
  - values.yaml : [OK/NOK]
  - templates/ : [OK/NOK]

Déploiements :
  - Installation simple : [OK/NOK]
  - Installation avec values : [OK/NOK]
  - Upgrade : [OK/NOK]
  - Rollback : [OK/NOK]

Charts du Hub :
  - Bitnami repo ajouté : [OK/NOK]
  - Chart installé : [OK/NOK]

Observations :
  - [observation 1]
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ Helm installé et fonctionnel
- ✓ Chart créé et testé
- ✓ Déploiements réussis

**Passez à : `10_comparaison.md`** pour la comparaison K3S / Docker / Docker Swarm.

---

**✅ Helm est opérationnel ! Comparons les technologies.**
