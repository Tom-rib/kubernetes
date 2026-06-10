# 🐳 Cours 03 - Docker Images (2 heures)

## 📚 Table des matières
1. [Concepts](#concepts)
2. [Anatomie d'une image](#anatomie)
3. [Registres](#registres)
4. [Dockerfile](#dockerfile)
5. [Building images](#building)
6. [Résumé](#résumé)

---

## 🎯 Concepts Fondamentaux

### Qu'est-ce qu'une image Docker ?

**Image Docker** = Template immuable pour créer des conteneurs

```
Image (Template)
    ↓ (docker run)
Conteneur (Instance)
    ↓
Process en exécution
```

### Analogie

```
Image = Classe (programmation objet)
Conteneur = Instance de la classe
```

### Caractéristiques

- ✓ **Immuable** : Ne change pas après création
- ✓ **Layered** : Composée de couches
- ✓ **Versionnable** : Tags (latest, v1.0, etc.)
- ✓ **Portable** : Fonctionne partout (Docker, K8s, etc.)
- ✓ **Léger** : Partage des couches

---

## 🏗️ Anatomie d'une Image

### Structure en couches

```
Image Docker
├─ Layer 1 : Base OS (Debian, Alpine, etc.)
├─ Layer 2 : Packages système (apt-get install)
├─ Layer 3 : Runtime (Python, Node, Java)
├─ Layer 4 : Dépendances app (pip install, npm install)
├─ Layer 5 : Code application
└─ Layer 6 : Configuration finale
```

### Exemple visuel

```
ubuntu:20.04 (120 MB)
    ├─ Layer 1 : OS kernel
    └─ Layer 2 : OS userland

RUN apt-get update && apt-get install python3
    ├─ Layer 3 : Python installation
    └─ Layer 4 : Dependencies

COPY app.py /app/
    └─ Layer 5 : Application code

CMD python3 app.py
    └─ Layer 6 : Configuration

==> Image finale (120 MB + modifications)
```

### Avantage : Réutilisabilité des couches

```
Image 1 (Python)
├─ Base: ubuntu:20.04
├─ Python 3.10
├─ Flask
└─ App 1

Image 2 (Python)
├─ Base: ubuntu:20.04 (RÉUTILISÉE)
├─ Python 3.10 (RÉUTILISÉE)
├─ Django
└─ App 2

Disque économisé ! Seulement 120 + (Flask) + (App 1) + (Django) + (App 2)
Au lieu de 120*2 + ...
```

---

## 📦 Registres d'images

### Registres publics

#### Docker Hub (index.docker.io)

```
Adresse : https://hub.docker.com
Gratuit : Oui (1 repo privé gratuit)
Auth : docker login

Télécharger :
docker pull nginx:latest
```

#### Autres registres

```
Quay.io (CoreOS) :
docker pull quay.io/coreos/etcd

GHCR (GitHub) :
docker pull ghcr.io/username/image:tag

Artifact Hub (CNCF) :
https://artifacthub.io
```

### Registres privés

```
Docker Registry (self-hosted)
├─ docker run registry:2
└─ Simple mais basique

Harbor (VMware)
├─ Interface web
├─ Scanning de vulnérabilités
└─ Replication

Artifactory (JFrog)
├─ Enterprise
├─ Multi-registry
└─ Policies avancées

ECR (AWS)
├─ Managed
├─ Intégration AWS
└─ Performance haute
```

### Nomenclature d'une image

```
registry.io/namespace/image:tag

Parties :
├─ registry.io : Serveur (docker.io par défaut)
├─ namespace : Groupe (library pour officielles)
├─ image : Nom du projet
└─ tag : Version

Exemples :
docker.io/library/nginx:latest
docker.io/library/nginx:1.25
ghcr.io/docker-library/mysql:8.0
myregistry.azurecr.io/myapp:v1.0.0
```

---

## 📝 Dockerfile

### Structure basique

```dockerfile
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y python3
COPY app.py /app/
WORKDIR /app
CMD python3 app.py
```

### Instructions principales

#### FROM

```dockerfile
FROM ubuntu:20.04
# Image de base obligatoire

FROM python:3.11
# Inclut déjà Python

FROM scratch
# Image vide (rarement utilisé)

FROM python:3.11-slim
# Version allégée
```

#### RUN

```dockerfile
# Exécute une commande
RUN apt-get update
RUN apt-get install -y nginx

# Mieux : Combinez pour réduire les layers
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean
```

#### COPY

```dockerfile
# Copie fichiers locaux dans l'image
COPY app.py /app/
COPY . /src/
COPY config.yaml /etc/app/
```

#### WORKDIR

```dockerfile
# Défini le répertoire de travail
WORKDIR /app
RUN mkdir -p data  # Crée /app/data
COPY . .           # Copie dans /app
```

#### ENV

```dockerfile
# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=8080
```

#### EXPOSE

```dockerfile
# Port écouté par l'app (info seulement)
EXPOSE 80
EXPOSE 3000

# Note : Doit être exposé avec -p au runtime
docker run -p 8080:80 myimage
```

#### CMD

```dockerfile
# Commande par défaut du conteneur
CMD ["python3", "app.py"]

# Peut être écrasée :
docker run myimage /bin/bash  # Lance bash au lieu de app.py
```

#### ENTRYPOINT

```dockerfile
# Comme CMD mais immuable
ENTRYPOINT ["python3"]
CMD ["app.py"]

# docker run myimage  → python3 app.py
# docker run myimage test.py → python3 test.py
```

---

## 🔨 Building Images

### Créer une image

```bash
# Build avec Dockerfile dans le répertoire courant
docker build -t myimage:latest .

# Build avec Dockerfile personnalisé
docker build -f Dockerfile.prod -t myapp:v1.0 .

# Build avec étapes de build (multi-stage)
docker build --target=production -t myapp:prod .
```

### Multi-stage builds

```dockerfile
# Stage 1 : Build
FROM python:3.11 AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install -r requirements.txt

# Stage 2 : Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /build /dependencies
COPY app.py .
CMD ["python3", "app.py"]
```

**Avantage** : Image finale petite (sans build tools)

### Optimiser la taille

```dockerfile
# ❌ 500 MB
FROM ubuntu:20.04
RUN apt-get install python3 python3-pip
RUN pip install Flask

# ✅ 100 MB
FROM python:3.11-slim
RUN pip install Flask

# ✅ 50 MB (Alpine)
FROM python:3.11-alpine
RUN pip install Flask
```

**Alpine** = Linux ultra-léger (5-50 MB pour les images)

---

## 📤 Publier une image

### Docker Hub

```bash
# Se connecter
docker login

# Tagguer l'image
docker tag myapp:latest username/myapp:latest

# Pusher
docker push username/myapp:latest

# Vérifier
curl https://hub.docker.com/v2/repositories/username/myapp/
```

### Registre privé

```bash
# Login privé
docker login myregistry.io

# Tagguer
docker tag myapp:latest myregistry.io/myapp:latest

# Pusher
docker push myregistry.io/myapp:latest
```

---

## 📦 Images populaires

### Officielles (Docker Library)

```
nginx
─ Web server
─ Minimal (150 MB)

python:3.11
─ Langage Python
─ Avec packages système (900 MB)

python:3.11-slim
─ Langage Python
─ Sans packages optionnels (200 MB)

node:18
─ Langage JavaScript
─ Avec npm (900 MB)

alpine
─ OS ultra-léger
─ 5 MB seulement
```

### Tags importants

```
latest
─ Dernière version (défaut)
─ Peut changer ! À éviter en production

1.0
─ Version spécifique
─ Stable et reproductible

1.0.0-alpine
─ Version + variante (petite)

v1.0.0-debian-12
─ Version + OS
```

---

## 🔍 Inspecting Images

```bash
# Lister les images
docker images

# Voir les détails
docker inspect nginx:latest
docker history nginx:latest

# Voir les layers
docker history --human nginx:latest
```

---

## 🎯 Best Practices

### 1. Utilisez des images officielles
```
✅ nginx (officielle, maintenue)
❌ mynginx (qui sait d'où ?)
```

### 2. Spécifiez le tag
```
✅ FROM nginx:1.25.1
❌ FROM nginx (latest varie)
```

### 3. Petit est beau
```
✅ FROM python:3.11-alpine (50 MB)
❌ FROM ubuntu + apt-get install (500 MB)
```

### 4. Une couche = Une modification
```
✅ RUN apt-get update && apt-get install && apt-get clean
❌ RUN apt-get update
   RUN apt-get install
   RUN apt-get clean
```

### 5. Utilisez .dockerignore
```
.git
node_modules
*.log
test/
```

---

## 📋 Résumé

### Concepts clés

| Concept | Explication |
|---------|------------|
| **Image** | Template immuable |
| **Conteneur** | Instance en exécution |
| **Layer** | Couche d'une image |
| **Registry** | Stockage d'images |
| **Tag** | Version d'une image |

### Dockerfile minimaliste

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
EXPOSE 8000
CMD ["python", "app.py"]
```

### Commandes essentielles

```bash
docker build -t myimage:1.0 .    # Créer
docker images                     # Lister
docker push myimage:1.0          # Publier
docker pull myimage:1.0          # Télécharger
```

---

## 🧪 Quiz d'auto-évaluation

- [ ] Je comprends les layers d'images Docker
- [ ] Je sais lire un Dockerfile
- [ ] Je peux créer une image personnalisée
- [ ] Je comprends les tags et versions
- [ ] Je sais pusher une image vers un registre

**Si tout est coché, vous maîtrisez Docker !** ✅

---

## 📚 Pour approfondir

- Pratiquer : Créer une image avec votre app
- Lire : https://docs.docker.com/build/
- Consulter : https://hub.docker.com/

---

*Fin du cours 03. Vous savez créer des images ! 🚀*
