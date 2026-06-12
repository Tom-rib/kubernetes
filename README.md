# 🐳 Projet Kubernetes - K3S Cluster Management

**Niveau** : 2e année Administration Systèmes & Réseaux  
**Durée estimée** : 40-50 heures  
**Objectif** : Maîtriser Kubernetes via K3S, déployer des applications conteneurisées, gérer la haute disponibilité et automatiser avec Helm.

---

## 📋 Sommaire

### 🎯 Vue d'ensemble
- [Présentation du projet](#présentation-du-projet)
- [Compétences visées](#compétences-visées)
- [Structure du dépôt](#structure-du-dépôt)

### 📚 Documentation par étape

| Job | Titre | Fichier |
|-----|-------|---------|
| **Préparation** | Prérequis, VMs, schéma réseau | [`01_preparation.md`](./01_preparation.md) |
| **Job 01** | Installation K3S sur 3 VMs | [`02_installation_k3s.md`](./02_installation_k3s.md) |
| **Job 02** | Déployer des apps (nginx, apache, MySQL) | [`03_applications_conteneurisees.md`](./03_applications_conteneurisees.md) |
| **Job 03** | Créer le cluster K3S (Master + Workers) | [`04_cluster_et_ha.md`](./04_cluster_et_ha.md) |
| **Job 04** | Haute disponibilité avec replicas | [`04_cluster_et_ha.md`](./04_cluster_et_ha.md) |
| **Job 05** | Volumes et stockage persistant | [`05_stockage_persistant.md`](./05_stockage_persistant.md) |
| **Job 06** | ConfigMaps et gestion de config | [`06_configmaps.md`](./06_configmaps.md) |
| **Job 07** | Secrets pour données sensibles | [`07_secrets.md`](./07_secrets.md) |
| **Job 08** | RBAC et sécurité | [`08_rbac.md`](./08_rbac.md) |
| **Job 09** | Helm - Package Manager | [`09_helm.md`](./09_helm.md) |
| **Aller plus loin** | K3S vs Docker vs Docker Swarm | [`10_comparaison.md`](./10_comparaison.md) |

### 📖 Ressources complémentaires
- [Cours Kubernetes](./Cours/README.md) - Concepts théoriques
- [Scripts et configs](./scripts/) - Fichiers de déploiement
- [Annexe - Commandes et dépannage](./05_annexes.md)

---

## 🎯 Présentation du projet

### Objectif principal
Construire un **cluster Kubernetes avec K3S** sur 3 VMs Debian, déployer des applications conteneurisées (nginx, Apache, MariaDB), implémenter la **haute disponibilité**, gérer le **stockage persistant**, et automatiser les déploiements avec **Helm**.

### Architecture finale
```
┌─────────────────────────────────────────┐
│     Cluster Kubernetes K3S              │
├─────────────────────────────────────────┤
│  kubes-01.local (MASTER)                │
│  - etcd, API Server, Controller Manager │
├─────────────────────────────────────────┤
│  kubes-02.local (WORKER)                │
│  - kubelet, kube-proxy                  │
├─────────────────────────────────────────┤
│  kubes-03.local (WORKER)                │
│  - kubelet, kube-proxy                  │
└─────────────────────────────────────────┘
         ↓
   Applications (Pods)
   - nginx (3 replicas - HA)
   - Apache (3 replicas - HA)
   - MariaDB (persistent volume)
```

### Résultats attendus
✅ 3 VMs Debian connectées en cluster K3S  
✅ Applications containerisées déployées  
✅ Haute disponibilité avec auto-scaling et failover  
✅ Stockage persistant pour données  
✅ Gestion sécurisée des configs et secrets  
✅ Contrôle d'accès (RBAC)  
✅ Déploiements automatisés via Helm  

---

## 🧠 Compétences visées

- ✓ **Administrer et sécuriser les infrastructures systèmes**
- ✓ **Administrer et sécuriser les infrastructures virtualisées**
- ✓ **Mettre en œuvre et optimiser la supervision des infrastructures**

### Savoir-faire acquis
| Compétence | Description |
|-----------|-------------|
| **Kubernetes** | Concepts, architecture, API, déploiement |
| **K3S** | Installation, configuration, cluster setup |
| **Containerisation** | Docker, images, registres |
| **Orchestration** | Pods, Deployments, StatefulSets, Services |
| **Stockage** | PV, PVC, SC, volumes persistants |
| **Sécurité** | RBAC, Secrets, NetworkPolicies |
| **Automation** | Helm charts, templating, GitOps |
| **Monitoring** | Logs, métriques, health checks |

---

## 🗂️ Structure du dépôt

```
projet-kubernetes/
├── README.md                    ← Vous êtes ici
├── Documentation.md             ← Réponse complète au sujet
├── Documentation.docx           ← Rendu Word pour présentation
│
├── Documentation/
│   ├── 01_preparation.md            ← Prérequis & schéma réseau
│   ├── 02_installation_k3s.md       ← Installation K3S (Job 01)
│   ├── 03_applications_conteneurisees.md  ← Déploiement apps (Job 02)
│   ├── 04_cluster_et_ha.md          ← Cluster + HA (Job 03-04)
│   ├── 05_stockage_persistant.md    ← Volumes (Job 05)
│   ├── 06_configmaps.md             ← Gestion config (Job 06)
│   ├── 07_secrets.md                ← Données sensibles (Job 07)
│   ├── 08_rbac.md                   ← Sécurité RBAC (Job 08)
│   ├── 09_helm.md                   ← Package manager (Job 09)
│   ├── 10_comparaison.md            ← K3S vs alternatives
│   ├── 05_annexes.md                ← Mémos, commandes, troubleshooting
│
├── Cours/
│   ├── README.md                ← Index des cours
│   ├── 01_kubernetes_basics.md  ← Concepts K8s
│   ├── 02_k3s_architecture.md   ← Architecture K3S
│   ├── 03_docker_images.md      ← Images Docker
│   ├── 04_networking.md         ← Réseau K8s
│   └── 05_helm_concepts.md      ← Helm théorique
│
├── scripts/
│   ├── 01_setup_vms.sh          ← Provisionner 3 VMs
│   ├── 02_install_k3s.sh        ← Installer K3S
│   ├── 03_join_cluster.sh       ← Joindre le cluster
│   ├── 04_deploy_apps.sh        ← Déployer les apps
│   ├── 05_test_ha.sh            ← Tester la HA
│   └── manifests/
│       ├── nginx-deployment.yaml
│       ├── apache-deployment.yaml
│       ├── mariadb-deployment.yaml
│       └── helm-values.yaml
│
└── logs/
    ├── installation.log         ← Logs des commandes exécutées
    └── tests.log               ← Résultats des tests

```

---

## 🚀 Démarrage rapide

### 1️⃣ Lire d'abord
Commencez par [`01_preparation.md`](./01_preparation.md) pour comprendre l'architecture et les prérequis.

### 2️⃣ Suivre étape par étape
Chaque fichier (02, 03, 04...) correspond à un Job. Lisez et exécutez les commandes dans l'ordre.

### 3️⃣ Documenter votre progression
À chaque étape, notez les commandes exécutées et les résultats dans le fichier `logs/installation.log`.

### 4️⃣ Tester vos déploiements
Utilisez les sections **Vérification** de chaque étape pour valider vos résultats.

### 5️⃣ Créer votre présentation
Utilisez les fichiers de documentation et les captures d'écran pour préparer votre présentation finale.

---

## 🎓 Résumé des concepts clés

### Kubernetes (K8s)
Système d'orchestration de conteneurs pour déployer, scaler et gérer des applications containerisées.

### K3S
Distribution légère de Kubernetes (5-10 MB) idéale pour apprendre et les environnements edge.

### Cluster
Ensemble de nœuds (master + workers) collaborant pour exécuter des workloads containerisés.

### Pod
Unité la plus petite dans Kubernetes - contient un ou plusieurs conteneurs.

### Deployment
Objet déclaratif pour déployer et scaler des pods avec haute disponibilité.

### Service
Expose les pods pour permettre la communication interne/externe.

### Volume
Stockage persistant pour les données au-delà du cycle de vie des pods.

### Helm
Package manager pour Kubernetes - facilite le déploiement et la gestion des applications.

---

## 📞 Support et dépannage

Consultez [`05_annexes.md`](./05_annexes.md) pour :
- ❌ Erreurs courantes et solutions
- 🔍 Commandes de diagnostic
- 📊 Monitoring et logs
- 🛠️ Mémos rapides


---

## 📅 Dernière mise à jour
Juin 2026 - Documentation pour niveau L2 Admin Sys & Réseaux

**Auteur** : Ribero Tom 
**Classe** : B2 Administrateur Système et Réseau  

---

**Bonne chance ! 💪 N'hésitez pas à relire les concepts théoriques dans le dossier `Cours/` avant chaque étape.**
