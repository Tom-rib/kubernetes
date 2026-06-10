# 📋 SUJET - Projet Kubernetes K3S

**Niveau :** 2e année | Administration Systèmes et Réseaux  
**Durée :** 4-5 semaines  
**Évaluation :** Présentation + support écrit

---

## 🎯 Introduction du sujet

Ce projet vise à acquérir une **maîtrise complète de Kubernetes** et de son implémentation K3S, du déploiement initial jusqu'à la gestion avancée d'un cluster de production.

### 📚 Objectifs pédagogiques

✅ Comprendre les **concepts de base** de Kubernetes  
✅ Installer et configurer un **cluster Kubernetes complet**  
✅ Déployer et gérer des **applications conteneurisées**  
✅ Utiliser les **Services**, **Volumes**, **ConfigMaps**, et **Secrets**  
✅ Superviser et gérer un **cluster Kubernetes**  
✅ Comprendre et utiliser **Helm** pour déployer des applications  

---

## ⚠️ Points importants

> 📖 **Merci de lire complètement cet ordre de mission avant de commencer !**

> 📝 **Pensez à documenter les commandes et étapes que vous suivez tout au long de la mission**

---

## 🚀 Jobs à réaliser

### **JOB 01** — Infrastructure & Installation de base

**Objectif :** Préparer l'infrastructure et installer K3S en mode standalone

📋 **Tâches :**
- Créer **3 VMs Debian** (sans GUI)
  - VM 1 : `kubes-01.local` 
  - VM 2 : `kubes-02.local` 
  - VM 3 : `kubes-03.local` 
- Installer **K3S sur chaque VM**

📌 **Livrables attendus :**
- 3 VMs Debian fonctionnelles
- K3S installé et validé sur chaque VM

---

### **JOB 02** — Déploiement d'applications conteneurisées

**Objectif :** Déployer les applications avant la mise en cluster

📋 **Tâches :**
- Déployer sur **chaque VM** :
  - **Nginx** (serveur web)
  - **Apache** (serveur web)
  - **MySQL/MariaDB** (base de données)
- Vérifier le bon fonctionnement de chaque application

📌 **Livrables attendus :**
- 3 applications x 3 VMs = 9 applications déployées
- Tests de connectivité réussis

---

### **JOB 03** — Formation du Cluster K3S

**Objectif :** Créer un cluster K3S distribué

📋 **Tâches :**
- Choisir **1 VM comme Master**
- Configurer les **2 autres VMs comme Workers**
- Valider que les **applications persistent** après la mise en cluster
- Vérifier la distribution des pods

📌 **Livrables attendus :**
- Cluster K3S fonctionnel (1 Master + 2 Workers)
- Tous les pods visibles et en exécution
- Communication inter-nodes validée

---

### **JOB 04** — Haute Disponibilité (HA) & Résilience

**Objectif :** Implémenter la haute disponibilité et tester la résilience

📋 **Tâches :**
- **Supprimer** toutes les applications actuelles
- **Réinstaller** les applications avec :
  - **Replicas activées** (minimum 2 replicas par application)
  - **High Availability** (HA) configurée
- **Tester la HA** en :
  - Arrêtant 1 worker
  - Vérifiant que **toutes les applications sont redéployées** automatiquement
  - Vérifiant le basculement sans interruption de service

📌 **Livrables attendus :**
- Deployments avec replicas (minimum 2)
- Tests de failover documentés
- Preuves de redéploiement automatique

---

### **JOB 05** — Gestion du Stockage Persistant

**Objectif :** Mettre en place le stockage persistant pour les données

📋 **Tâches :**
Les **Volumes** permettent à vos applications de conserver des données même après le redémarrage des pods.

- Mettre en place **PersistentVolumes (PV)** et **PersistentVolumeClaim (PVC)**
- Configurer le stockage persistant pour :
  - **Nginx** (données web)
  - **MariaDB** (données de base de données)
- Valider la **persistance des données** après redémarrage

📌 **Livrables attendus :**
- PersistentVolumes créés et montés
- Volumes de données fonctionnels
- Tests de persistance réussis

---

### **JOB 06** — Configuration avec ConfigMaps

**Objectif :** Gérer la configuration des applications de manière flexible

📋 **Tâches :**
- Créer des **ConfigMaps** pour :
  - Fichiers de configuration Nginx
  - Fichiers de configuration Apache
  - Variables d'environnement applicatives
- Injecter les ConfigMaps dans les pods
- Valider que les configurations sont bien appliquées

📌 **Livrables attendus :**
- ConfigMaps pour chaque application
- Pods utilisant les ConfigMaps
- Configuration vérifiée et fonctionnelle

---

### **JOB 07** — Gestion des données sensibles avec Secrets

**Objectif :** Sécuriser les données sensibles

📋 **Tâches :**
Données sensibles « Secret » — À activer pour le conteneur MariaDB

- Créer des **Secrets Kubernetes** pour :
  - **Identifiants MariaDB** (username/password)
  - **Root password** de MariaDB
- Injecter les secrets dans le pod MariaDB
- Valider l'authentification avec les secrets

📌 **Livrables attendus :**
- Secrets créés et sécurisés
- MariaDB authentifiée via secrets
- Pas de mots de passe en clair

---

### **JOB 08** — Sécurité avec RBAC

**Objectif :** Implémenter le contrôle d'accès basé sur les rôles

📋 **Tâches :**
- Mettre en place les **Règles RBAC** (Role-Based Access Control) :
  - Créer des **Roles** adaptés
  - Créer des **RoleBindings** pour les utilisateurs/services
  - Tester les permissions
- Restreindre l'accès aux ressources par utilisateur

📌 **Livrables attendus :**
- Roles et RoleBindings configurés
- Tests de permissions documentés
- Sécurité validée

---

### **JOB 09** — Helm - Gestionnaire de packages

**Objectif :** Maîtriser Helm pour le déploiement et la gestion des applications

📋 **Tâches :**
- Installer et configurer **Helm 3**
- Rechercher et installer des **Helm Charts**
- Personnaliser les charts (values.yaml)
- Mettre à jour et désinstaller des applications
- Gérer des applications complexes via charts

**Opérations à maîtriser :**
- `helm search` — Rechercher des charts
- `helm install` — Installer une application
- `helm upgrade` — Mettre à jour une application
- `helm uninstall` — Supprimer une application
- `helm values` — Personnaliser les configurations

📌 **Livrables attendus :**
- Helm installé et fonctionnel
- Au moins 2 applications déployées via Helm
- Charts personnalisés
- Mise à jour et suppression validées

---

## 🎓 Pour aller plus loin

**Étude comparative des technologies d'orchestration :**

- Comparer **K3S** avec **Docker** et **Docker Swarm**
- Avantages et inconvénients de chaque solution
- Cas d'usage appropriés pour chacun
- Recommandations selon le contexte

---

## 📊 Compétences visées

| Domaine | Compétence |
|---------|-----------|
| **Systèmes** | ➔ Administrer et sécuriser les infrastructures systèmes |
| **Virtualisation** | ➔ Administrer et sécuriser les infrastructures virtualisées |
| **Supervision** | ➔ Mettre en œuvre et optimiser la supervision des infrastructures |

---

## 📚 Base de connaissances requise

Vous devrez approfondir vos connaissances sur :

- **K3S** — Distribution Kubernetes légère
- **Kubernetes** — Concepts fondamentaux et avancés
- **Helm** — Gestionnaire de packages Kubernetes

---

## 📋 Rendu attendu

### Format de présentation

**L'évaluation se fera sous forme de présentation avec support à l'équipe pédagogique.**

📌 **Éléments à inclure :**
- ✅ Présentation slidée (PowerPoint/PDF)
- ✅ Démonstration live du cluster
- ✅ Documentation écrite complète
- ✅ Réponses aux questions techniques
- ✅ Explications des choix architecturaux

---

**Bon courage ! 🚀**

---

*Document sujet — Kubernetes K3S | 2e année Admin Sys & Réseaux*