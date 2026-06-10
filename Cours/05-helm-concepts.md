# 🎁 Cours 05 - Helm Concepts (1.5 heures)

## 📚 Table des matières
1. [Introduction](#introduction)
2. [Helm vs kubectl](#helm-vs-kubectl)
3. [Anatomie d'un Chart](#anatomie)
4. [Templating](#templating)
5. [Lifecycle](#lifecycle)
6. [Best Practices](#best-practices)
7. [Résumé](#résumé)

---

## 🎯 Introduction

### Durée : 1.5 heures
### Niveau : Intermédiaire
### Prérequis : Cours 01-04

### Objectifs
- ✅ Comprendre Helm et son modèle
- ✅ Maîtriser les charts Helm
- ✅ Déployer via Helm
- ✅ Customiser les configurations

---

## Helm = npm de Kubernetes

### Analogie

```
npm   → Gère packages Node.js
pip   → Gère packages Python
apt   → Gère packages Debian
Helm  → Gère applications Kubernetes
```

### Comparaison : kubectl vs Helm

#### Avec kubectl

```bash
# 1. Créer le manifest
cat deployment.yaml
# nginx-deployment.yaml (static)

# 2. Appliquer
kubectl apply -f deployment.yaml

# 3. Mettre à jour : éditer le fichier
nano deployment.yaml
kubectl apply -f deployment.yaml

# 4. Rollback : git restore, puis apply
git restore deployment.yaml
kubectl apply -f deployment.yaml

# 5. Multi-environnements : Copier/adapter fichiers
cp deployment.yaml deployment-prod.yaml
nano deployment-prod.yaml
```

#### Avec Helm

```bash
# 1. Chart existe
helm repo add bitnami https://charts.bitnami.com/bitnami

# 2. Installer (1 ligne)
helm install my-nginx bitnami/nginx

# 3. Mettre à jour
helm upgrade my-nginx bitnami/nginx --set replicas=5

# 4. Rollback
helm rollback my-nginx

# 5. Multi-environnements : Values files
helm install my-nginx bitnami/nginx -f values-dev.yaml
helm install my-nginx bitnami/nginx -f values-prod.yaml
```

### Avantages de Helm

- ✅ **Réutilisable** : Chart une fois, utiliser partout
- ✅ **Paramétrable** : Values pour customiser
- ✅ **Versionnage** : Releases avec historique
- ✅ **Rollback** : Revenir facile
- ✅ **Dependency** : Charts dépendant d'autres charts
- ✅ **Templating** : Jinja2-like pour générer YAML

---

## 🏗️ Anatomie d'un Chart

### Structure

```
my-app-chart/
├─ Chart.yaml              # Métadonnées du chart
├─ values.yaml             # Valeurs par défaut
├─ values-prod.yaml        # Valeurs production (optionnel)
├─ templates/
│  ├─ deployment.yaml      # Template Deployment
│  ├─ service.yaml         # Template Service
│  ├─ configmap.yaml       # Template ConfigMap
│  ├─ ingress.yaml         # Template Ingress
│  ├─ _helpers.tpl         # Helper functions
│  └─ NOTES.txt            # Messages post-install
├─ charts/                 # Dependencies (optionnel)
│  └─ postgresql/
└─ README.md               # Documentation
```

### Chart.yaml

```yaml
apiVersion: v2
name: my-app              # Nom du chart
description: My application
type: application         # Ou library
version: 1.0.0           # Version du chart
appVersion: "1.0.0"      # Version de l'app
keywords:
  - kubernetes
  - app
maintainers:
  - name: John Doe
    email: john@example.com
dependencies:
  - name: postgresql
    version: "11.0.0"
    repository: "https://charts.bitnami.com/bitnami"
```

### values.yaml

```yaml
# Valeurs par défaut
replicaCount: 3

image:
  repository: myapp
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 8080

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"

ingress:
  enabled: false
  host: myapp.example.com

database:
  host: localhost
  port: 5432
  username: admin
  password: secret
```

---

## 🎨 Templating

### Variables Helm

```yaml
# values.yaml
myValue: "Hello"
image:
  repository: nginx
  tag: 1.25

# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}  # Accès values
  template:
    spec:
      containers:
      - name: app
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### Variables intégrées

```
{{ .Release.Name }}      # Nom de la release (ex: my-nginx)
{{ .Release.Namespace }}  # Namespace (ex: default)
{{ .Chart.Name }}        # Nom du chart (ex: nginx)
{{ .Chart.Version }}     # Version du chart (ex: 15.0.0)
{{ .Chart.AppVersion }}  # Version de l'app
```

### Logique conditionnelle

```yaml
# values.yaml
ingress:
  enabled: true

# templates/ingress.yaml
{{ if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
spec:
  rules:
  - host: {{ .Values.ingress.host }}
{{ end }}
```

**Résultat** : Ingress créée seulement si enabled: true

### Boucles

```yaml
# values.yaml
ports:
  - 80
  - 443
  - 8080

# templates/deployment.yaml
ports:
{{ range .Values.ports }}
  - containerPort: {{ . }}
{{ end }}

# Résultat :
# ports:
#   - containerPort: 80
#   - containerPort: 443
#   - containerPort: 8080
```

### Fonctions Helm

```yaml
{{ .Values.image.repository | quote }}
# Résultat : "myapp"

{{ .Values.app.name | upper }}
# Résultat : MYAPP

{{ .Values.config | toJson }}
# Résultat : JSON

{{ include "my-app.labels" . }}
# Résultat : Inclut le template _helpers.tpl
```

### Helpers (_helpers.tpl)

```yaml
# templates/_helpers.tpl
{{- define "my-app.labels" -}}
app: {{ .Chart.Name }}
version: {{ .Chart.Version }}
{{- end }}

# templates/deployment.yaml
metadata:
  labels:
    {{- include "my-app.labels" . | nindent 4 }}

# Résultat :
# metadata:
#   labels:
#     app: my-app
#     version: 1.0.0
```

---

## 🔄 Lifecycle Helm

### Release Lifecycle

```
1. Chart (template)
   ├─ Fichiers YAML avec variables
   └─ Pas encore déployé

2. helm install (avec values)
   ├─ Remplace variables par valeurs
   ├─ Valide la syntaxe
   └─ Crée manifests finaux

3. Release (instance)
   ├─ Historique de versions
   ├─ État dans le cluster
   └─ Peut être upgradée/downgraded

4. kubectl apply (manifests)
   ├─ Crée ressources K8s
   ├─ Pods démarrent
   └─ Services actifs
```

### Commandes principales

#### Install

```bash
# Installation basique
helm install my-release my-chart

# Avec namespace
helm install my-release my-chart -n production

# Avec values personnalisées
helm install my-release my-chart \
  --values values-prod.yaml \
  --set replicas=5 \
  --set image.tag=v2.0

# Générer manifests sans appliquer
helm install my-release my-chart --dry-run
```

#### Upgrade

```bash
# Mettre à jour une release
helm upgrade my-release my-chart

# Upgrade + install (idempotent)
helm upgrade --install my-release my-chart

# Upgrade avec de nouvelles valeurs
helm upgrade my-release my-chart \
  --values values-prod.yaml \
  --set replicas=10
```

#### Rollback

```bash
# Voir l'historique
helm history my-release

# Revenir à la version précédente
helm rollback my-release

# Revenir à une révision spécifique
helm rollback my-release 1
```

#### Uninstall

```bash
# Supprimer une release (supprime ressources)
helm uninstall my-release

# Garder une trace pour rollback
helm uninstall my-release --keep-history
```

### Vérifier l'état

```bash
# Lister les releases
helm list -n production

# Voir les valeurs appliquées
helm get values my-release

# Voir les manifests générés
helm get manifest my-release

# Voir les notes post-installation
helm get notes my-release
```

---

## 📦 Travailler avec Charts

### Créer un Chart

```bash
# Générer une structure de base
helm create my-app

# Cela crée :
my-app/
├─ Chart.yaml
├─ values.yaml
├─ templates/
│  ├─ deployment.yaml
│  ├─ service.yaml
│  └─ ...
└─ README.md
```

### Packages et Repositories

```bash
# Empaqueter le chart
helm package my-app
# Crée : my-app-1.0.0.tgz

# Ajouter un repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Lister les repositories
helm repo list

# Chercher des charts
helm search repo nginx

# Mettre à jour les repositories
helm repo update
```

### Chart Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "11.0.0"
    repository: "https://charts.bitnami.com/bitnami"
  - name: redis
    version: "17.0.0"
    repository: "https://charts.bitnami.com/bitnami"
```

```bash
# Télécharger les dépendances
helm dependency update my-app

# Cela crée : my-app/charts/postgresql/, redis/, ...
```

---

## 🎯 Best Practices

### 1. Utilisez les repositories officiels

```bash
✅ helm install my-nginx bitnami/nginx
❌ helm install my-nginx /local/nginx-chart
```

### 2. Spécifiez la version du chart

```bash
✅ helm install my-nginx bitnami/nginx --version 15.0.0
❌ helm install my-nginx bitnami/nginx (latest varie)
```

### 3. Utilisez un values file pour chaque environnement

```bash
helm install my-app my-chart -f values-dev.yaml
helm install my-app my-chart -f values-prod.yaml

# Au lieu de :
helm install my-app my-chart --set foo=bar --set baz=qux ...
```

### 4. Testez les manifests

```bash
# Avant d'installer
helm template my-release my-chart | kubectl apply --dry-run=client -f -

# Ou
helm install my-release my-chart --dry-run --debug
```

### 5. Utilisez des namespaces

```bash
helm install my-release my-chart -n production --create-namespace
helm install my-release my-chart -n staging --create-namespace
```

---

## 📊 Comparaison : Helm vs Manifests statiques

### Manifests statiques

```
deployment.yaml (statique)
deployment-prod.yaml (copie)
deployment-staging.yaml (copie)
...
→ Duplication, pas de versioning
```

### Helm Charts

```
my-app-chart/
├─ values.yaml (dev)
├─ values-prod.yaml (prod)
├─ values-staging.yaml (staging)
└─ templates/ (réutilisable)
→ Pas de duplication, versioning facile
```

---

## 📋 Résumé

### Concepts clés

| Terme | Explication |
|-------|------------|
| **Chart** | Package de templates |
| **Release** | Instance d'un chart |
| **Values** | Variables pour customiser |
| **Template** | Fichier YAML avec variables |
| **Repository** | Serveur de charts |

### Workflow typique

```
1. helm repo add <repo>
2. helm search repo <name>
3. helm values <chart>  # Voir les options
4. helm install <name> <chart> -f values.yaml
5. helm upgrade <name> <chart> --set key=value
6. helm rollback <name> (si problème)
```

### Installation vs Upgrade vs Rollback

```
Install : Crée une release
Upgrade : Modifie une release existante
Rollback : Revient à une révision antérieure
Uninstall : Supprime une release
```

---

## 🧪 Quiz d'auto-évaluation

- [ ] Je comprends le templating Helm
- [ ] Je peux créer un chart simple
- [ ] Je sais installer/upgrade/rollback
- [ ] Je comprends values override
- [ ] Je peux lire un chart existant

**Si tout est coché, vous maîtrisez Helm !** ✅

---

## 📚 Pour approfondir

- Pratiquer : Créer un chart personnalisé
- Lire : https://helm.sh/docs/
- Consulter : https://artifacthub.io/

---

*Fin du cours 05. Vous maîtrisez Kubernetes et Helm !* 🚀

**Félicitations ! Vous avez complété tous les cours théoriques !** 🎉

Prochaine étape : Faire le projet pratique pour mettre tout cela en œuvre.
