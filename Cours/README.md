# 📚 Cours Théoriques Kubernetes & K3S

Bienvenue dans la section cours théoriques ! Ces fichiers vous fourniront les fondations solides pour comprendre Kubernetes et K3S.

## 📖 Cours Disponibles

### 1. **01-kubernetes-basics.md** (2 heures)
**Durée** : 2 heures
**Niveau** : Débutant
**Prérequis** : Connaître Docker

**Sujets** :
- Architecture Master-Worker
- Concepts clés : Pod, Deployment, Service, Namespace
- Cycles de vie des pods
- Health checks (liveness, readiness)
- Rolling updates et rollback

**À l'issue du cours** :
- ✅ Vous comprenez l'architecture de Kubernetes
- ✅ Vous pouvez créer Deployments et Services
- ✅ Vous savez comment K8s gère la haute disponibilité

---

### 2. **02-k3s-architecture.md** (1.5 heures)
**Durée** : 1.5 heures
**Niveau** : Débutant
**Prérequis** : Cours 01

**Sujets** :
- Différences K3S vs Kubernetes complet
- Architecture légère de K3S
- Installation en 1 ligne de commande
- Configuration et déploiement
- Storage et networking dans K3S

**À l'issue du cours** :
- ✅ Vous comprenez pourquoi K3S existe
- ✅ Vous pouvez installer un cluster K3S
- ✅ Vous savez joindre des workers

---

### 3. **03-docker-images.md** (2 heures)
**Durée** : 2 heures
**Niveau** : Débutant
**Prérequis** : Cours 01-02

**Sujets** :
- Structure des images Docker (layers)
- Registres d'images (Docker Hub, private)
- Écrire des Dockerfile
- Build et pushing d'images
- Optimisation de taille
- Best practices Docker

**À l'issue du cours** :
- ✅ Vous comprenez comment les images Docker fonctionnent
- ✅ Vous pouvez créer des images personnalisées
- ✅ Vous savez publier vers un registre

---

### 4. **04-networking.md** (2 heures)
**Durée** : 2 heures
**Niveau** : Intermédiaire
**Prérequis** : Cours 01-03

**Sujets** :
- Services : ClusterIP, NodePort, LoadBalancer, ExternalName
- DNS interne et CoreDNS
- Ingress et Ingress Controllers
- Network Policies (pare-feu pour pods)
- Debugging réseau

**À l'issue du cours** :
- ✅ Vous savez exposer vos applications
- ✅ Vous comprenez le networking K8s
- ✅ Vous pouvez créer des Ingress

---

### 5. **05-helm-concepts.md** (1.5 heures)
**Durée** : 1.5 heures
**Niveau** : Intermédiaire
**Prérequis** : Cours 01-04

**Sujets** :
- Helm vs kubectl
- Anatomie d'un Chart Helm
- Templating Helm (variables, logique, fonctions)
- Lifecycle (install, upgrade, rollback)
- Dépendances et repositories
- Best practices

**À l'issue du cours** :
- ✅ Vous comprenez Helm et son modèle
- ✅ Vous pouvez déployer avec Helm
- ✅ Vous savez créer des charts personnalisés

---

## 🎯 Plan d'étude recommandé

### Semaine 1 : Fondations (Beginner)

```
Lundi    : 01-kubernetes-basics.md (2h)
Mardi    : 02-k3s-architecture.md (1.5h)
Mercredi : 03-docker-images.md (2h)
Jeudi    : 04-networking.md (2h)
Vendredi : 05-helm-concepts.md (1.5h)

Total : 9 heures de cours
```

### Semaine 2 : Pratique (Hands-on)

```
Lundi-Vendredi : Faire le projet Kubernetes
                 (30-40 heures)

Utiliser les cours comme référence
```

---

## 📊 Statistiques des Cours

| Cours | Durée | Lignes | Concepts | Exemples |
|-------|-------|--------|----------|----------|
| 01 - K8s Basics | 2h | 800+ | 10+ | 30+ |
| 02 - K3S Arch | 1.5h | 600+ | 8+ | 20+ |
| 03 - Docker | 2h | 700+ | 9+ | 25+ |
| 04 - Networking | 2h | 800+ | 9+ | 30+ |
| 05 - Helm | 1.5h | 700+ | 10+ | 25+ |
| **TOTAL** | **9h** | **3600+** | **46+** | **130+** |

---

## 🎓 Progression Pédagogique

```
Cours 01 : Concepts fondamentaux
   ↓
Cours 02 : Implémentation légère (K3S)
   ↓
Cours 03 : Fondation des applications (Docker)
   ↓
Cours 04 : Exposition et communication (Networking)
   ↓
Cours 05 : Déploiement et gestion (Helm)
   ↓
Projet pratique : Tout mettre ensemble !
```

---

## 💡 Comment Utiliser ces Cours

### Lecture Progressive

```bash
# Lire le fichier 01
cat 01-kubernetes-basics.md | less

# Prendre des notes
# Essayer les exemples

# Passer au suivant quand maîtrisé
```

### Apprentissage Ciblé

```bash
# Chercher un concept spécifique
grep -n "Pod" 01-kubernetes-basics.md

# Lire juste cette section
```

### Révision Rapide

```bash
# Lire les résumés (Résumé, Quiz)
# Vérifier les points clés
```

---

## 🧪 Quiz d'Auto-Évaluation

Chaque cours termine par un **Quiz d'auto-évaluation**.

**Checklist après Cours 01 : Kubernetes Basics**
- [ ] Je peux expliquer l'architecture Master-Worker
- [ ] Je sais ce qu'est un Pod et ses propriétés
- [ ] Je comprends Deployment et ReplicaSet
- [ ] Je sais les types de Services
- [ ] Je peux décrire un Namespace

**Checklist après Cours 02 : K3S Architecture**
- [ ] Je comprends les différences K3S vs Kubernetes
- [ ] Je peux installer K3S en 1 ligne
- [ ] Je sais joindre un worker au cluster
- [ ] Je comprends la structure K3S
- [ ] Je peux configurer kubeconfig localement

**Checklist après Cours 03 : Docker Images**
- [ ] Je comprends les layers d'images Docker
- [ ] Je sais lire un Dockerfile
- [ ] Je peux créer une image personnalisée
- [ ] Je comprends les tags et versions
- [ ] Je sais pusher une image vers un registre

**Checklist après Cours 04 : Networking**
- [ ] Je sais les types de Services
- [ ] Je comprends DNS interne
- [ ] Je peux créer une Ingress
- [ ] Je comprends les basiques de NetworkPolicy
- [ ] Je peux troubleshooter la connectivité

**Checklist après Cours 05 : Helm Concepts**
- [ ] Je comprends le templating Helm
- [ ] Je peux créer un chart simple
- [ ] Je sais installer/upgrade/rollback
- [ ] Je comprends values override
- [ ] Je peux lire un chart existant

---

## 🔗 Navigation Inter-cours

### Dépendances entre cours

```
01-kubernetes-basics.md
     ↓
02-k3s-architecture.md
     ↓
03-docker-images.md
     ↓
04-networking.md
     ↓
05-helm-concepts.md
```

**Vous pouvez les suivre dans cet ordre** (progression linéaire).

---

## 📚 Ressources Supplémentaires

### Documentation officielle
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [K3S Docs](https://docs.k3s.io/)
- [Docker Docs](https://docs.docker.com/)
- [Helm Docs](https://helm.sh/docs/)

### Tutoriels vidéo
- [Kubernetes in 100 Seconds](https://www.youtube.com/watch?v=PziYWLKQyvQ) (YouTube)
- [Docker Mastery](https://www.udemy.com/course/docker-mastery/) (Udemy)

### Communautés
- [CNCF Slack](https://cloud-native.slack.com/)
- [r/kubernetes](https://www.reddit.com/r/kubernetes/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)

---

## 🎯 Objectifs Globaux après tous les cours

Après avoir terminé tous les 5 cours, vous saurez :

### Théorie
- ✅ Architecture et concepts Kubernetes
- ✅ Structure et design de K3S
- ✅ Création d'images Docker
- ✅ Networking et exposition dans K8s
- ✅ Templating et gestion d'applications avec Helm

### Pratique
- ✅ Créer et configurer un cluster K3S
- ✅ Déployer des applications avec Deployments
- ✅ Exposer des services
- ✅ Gérer la configuration avec ConfigMaps
- ✅ Gérer les secrets
- ✅ Implémenter le networking
- ✅ Utiliser Helm pour le déploiement avancé

### Compétences
- ✅ Administration Kubernetes
- ✅ DevOps et Cloud Native
- ✅ Troubleshooting et debugging
- ✅ Architecture d'infrastructure

---

## 📝 Format des Cours

Chaque cours suit ce format :

```
📚 Table des matières
🎯 Objectifs du cours
🏗️ Concepts principaux
   ├─ Explications
   ├─ Diagrammes
   ├─ Exemples
   └─ Analogies
💡 Best practices
🧪 Quiz d'auto-évaluation
📚 Pour approfondir
```

---

## ⏱️ Durée estimée

```
Lecture seule        : 9 heures
Lecture + exemples   : 15 heures
Lecture + exercices  : 25 heures
Lecture + labo       : 40 heures (incluant projet)
```

---

## 🚀 Après les Cours

Une fois tous les cours terminés, vous êtes prêt pour :

1. **Le Projet K3S** (30-40 heures)
   - Applique tous les concepts appris
   - Pratique guidée complète

2. **DevOps avancé**
   - CI/CD pipelines
   - Monitoring et logging
   - Security et RBAC

3. **Certifications**
   - CKA (Certified Kubernetes Administrator)
   - CKAD (Certified Kubernetes Application Developer)

---

## 💬 Questions Fréquentes

**Q : Dans quel ordre dois-je lire les cours ?**
A : Dans l'ordre : 01 → 02 → 03 → 04 → 05

**Q : Combien de temps pour les lire tous ?**
A : 9 heures de lecture, mais prévoyez 15-25 heures avec exercices

**Q : Puis-je sauter certains cours ?**
A : Non, ils sont progressifs. Chaque cours s'appuie sur le précédent.

**Q : Comment valider que j'ai compris ?**
A : Cochez le quiz d'auto-évaluation de chaque cours

**Q : Puis-je revenir lire un cours spécifique ?**
A : Oui ! Consultez-les comme référence du projet

---

## ✅ Checklist Avant de Commencer

- [ ] J'ai au moins 10 heures libres cette semaine
- [ ] J'ai Docker installé pour les exemples
- [ ] J'ai un éditeur de texte pour prendre des notes
- [ ] Je suis prêt à apprendre des nouveaux concepts
- [ ] Je vais faire les exercices proposés

---

## 🎯 Bon à Savoir

- Les cours sont **indépendants du projet** mais **complémentaires**
- Vous pouvez les lire **avant ou en même temps** que le projet
- Chaque cours a des **quizzes d'auto-évaluation** pour vérifier
- Les concepts sont **progressifs et construisent les uns sur les autres**
- Vous pouvez utiliser les cours comme **référence pendant le projet**

---

**Commencez par le cours 01 et bonne lecture ! 📖**

Questions ? Consultez la documentation officielle ou les ressources listées ci-dessus.

---

*Créé avec ❤️ pour les étudiants en administration systèmes et réseaux*
