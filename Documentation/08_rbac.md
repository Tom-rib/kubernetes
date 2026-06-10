# 08 - RBAC et Sécurité (Job 08)

## 🎯 Objectif
Implémenter le contrôle d'accès basé sur les rôles (**RBAC - Role Based Access Control**) pour sécuriser le cluster Kubernetes.

## 📋 Table des matières
1. [Concepts RBAC](#concepts-rbac)
2. [Créer un User](#créer-un-user)
3. [Créer un Role](#créer-un-role)
4. [Lier Role et User](#lier-role-et-user)
5. [Tester les permissions](#tester-les-permissions)

---

## 💡 Concepts RBAC

### Composants RBAC
1. **Subject** : Qui ? (User, ServiceAccount, Group)
2. **Verb** : Quoi faire ? (get, create, delete, etc.)
3. **Resource** : Sur quoi ? (pods, services, secrets, etc.)

### Exemple
```
User: alice
Role: pod-reader
  - Verb: get, list, watch
  - Resource: pods
Namespace: default
```

### Objets Kubernetes pour RBAC

| Objet | Portée | Description |
|-------|--------|-------------|
| **Role** | Namespace | Permissions dans 1 namespace |
| **ClusterRole** | Cluster | Permissions dans tout le cluster |
| **RoleBinding** | Namespace | Associe Role → Subject |
| **ClusterRoleBinding** | Cluster | Associe ClusterRole → Subject |

---

## 👤 Créer un User

### Étape 1 : Créer un certificat client

```bash
# Variables
USERNAME="alice"
NAMESPACE="default"

# Créer une clé privée
openssl genrsa -out $USERNAME.key 2048

# Créer une demande de signature (CSR)
openssl req -new \
  -key $USERNAME.key \
  -out $USERNAME.csr \
  -subj "/CN=$USERNAME/O=developers"
```

### Étape 2 : Signer le certificat avec la CA du cluster

```bash
# Localiser la CA du cluster
CA_CERT=/etc/rancher/k3s/server/tls/server-ca.crt
CA_KEY=/etc/rancher/k3s/server/tls/server-ca.key

# Signer le certificat
sudo openssl x509 -req \
  -in $USERNAME.csr \
  -CA $CA_CERT \
  -CAkey $CA_KEY \
  -CAcreateserial \
  -out $USERNAME.crt \
  -days 365

# Vérifier
openssl x509 -in $USERNAME.crt -text -noout
```

### Étape 3 : Créer le contexte kubectl pour l'utilisateur

```bash
# Ajouter l'utilisateur au kubeconfig
kubectl config set-credentials alice \
  --client-certificate=$USERNAME.crt \
  --client-key=$USERNAME.key

# Créer un contexte
kubectl config set-context alice-context \
  --cluster=default \
  --namespace=default \
  --user=alice

# Vérifier
kubectl config get-contexts
```

### Étape 4 : Tester l'accès (sans permissions encore)

```bash
# Essayer de lister les pods
kubectl --context=alice-context get pods
# Expected: Error - forbidden

# Revenir à l'utilisateur admin
kubectl config current-context
```

---

## 🔐 Créer un Role

### Role : Lecteur de pods

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

Expliquer :
- **apiGroups: [""]** : API core (pods, services, etc.)
- **resources: ["pods"]** : Ressource pods
- **verbs: ["get", "list", "watch"]** : Autorise à lire les pods

### Role : Lecteur de secrets

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
```

### Role : Admin complet

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### Verbes courants
| Verbe | Description |
|-------|-----------|
| **get** | Lire une ressource |
| **list** | Lister les ressources |
| **watch** | Observer les changements |
| **create** | Créer une ressource |
| **update** | Modifier une ressource |
| **patch** | Modifier partiellement |
| **delete** | Supprimer une ressource |
| **deletecollection** | Supprimer une collection |
| **exec** | Exécuter dans un pod |
| **logs** | Voir les logs |

---

## 🔗 Lier Role et User (RoleBinding)

### Créer un RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Appliquer :

```bash
kubectl apply -f rolebinding.yaml

# Vérifier
kubectl get rolebinding
kubectl describe rolebinding read-pods
```

---

## 🧪 Tester les permissions

### Test 1 : Alice peut lire les pods

```bash
# Avec alice
kubectl --context=alice-context get pods
# Expected: liste des pods

# Détails d'un pod
kubectl --context=alice-context get pod nginx-deployment-xyz -o yaml
# Expected: OK

# Watch les pods
kubectl --context=alice-context get pods --watch
```

### Test 2 : Alice ne peut pas créer de pods

```bash
# Essayer de créer un pod
kubectl --context=alice-context create deployment test --image=nginx
# Expected: Error - forbidden
```

### Test 3 : Alice ne peut pas voir les secrets

```bash
# Essayer de lire un secret
kubectl --context=alice-context get secrets
# Expected: Error - forbidden
```

### Test 4 : Ajouter la permission secrets

Créer un RoleBinding pour les secrets :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: default
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

Appliquer et tester :

```bash
kubectl apply -f secret-rolebinding.yaml

# Maintenant alice peut voir les secrets
kubectl --context=alice-context get secrets
# Expected: OK
```

---

## 📋 Exemple complet : Développeur avec permissions limitées

Fichier `developer-rbac.yaml` :

```yaml
---
# Créer un namespace pour le développeur
apiVersion: v1
kind: Namespace
metadata:
  name: development
---
# Role pour les développeurs
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: development
rules:
# Pods
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Pods logs
- apiGroups: [""]
  resources: ["pods/logs"]
  verbs: ["get", "list"]
# Pods exec
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
# Services
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch"]
# Deployments
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# ConfigMaps
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Secrets (lecture seule)
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
# RoleBinding : dev-user dans le namespace development
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding : lecture de pods dans default
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-read-default
  namespace: default
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Appliquer :

```bash
kubectl apply -f developer-rbac.yaml

# Vérifier
kubectl get namespaces
kubectl get role -n development
kubectl get rolebinding -n development
```

---

## 📋 ServiceAccounts

Les pods utilisent aussi les ServiceAccounts pour accéder à l'API :

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      serviceAccountName: app-sa
      containers:
      - name: app
        image: myapp:latest
```

---

## ✅ Vérification

### Check 1 : Utilisateurs créés

```bash
kubectl config get-users
```

### Check 2 : Roles et RoleBindings

```bash
kubectl get roles
kubectl get rolebindings
kubectl get clusterroles
kubectl get clusterrolebindings
```

### Check 3 : Permissions effectives

```bash
# Voir quels verbes alice peut faire sur les pods
kubectl auth can-i get pods --as=alice
# Expected: yes

kubectl auth can-i create pods --as=alice
# Expected: no

kubectl auth can-i delete secrets --as=alice
# Expected: no
```

### Check 4 : Audit des permissions

```bash
# Afficher les permissions d'un utilisateur
kubectl get rolebinding -A -o jsonpath='{range .items[*]}{.subjects[?(@.name=="alice")].name}{" -> "}{.roleRef.name}{"\n"}{end}'
```

---

## 📝 Bonnes pratiques

✅ **À faire**
- Utiliser des Roles granulaires
- Limiter les permissions (principle of least privilege)
- Utiliser des ServiceAccounts pour les pods
- Auditer régulièrement les permissions

❌ **À éviter**
- Donner cluster-admin à tous
- Utiliser `verbs: ["*"]`
- Stocker les certificats en dur dans les pods
- Ignorer les avertissements RBAC

---

## 📝 Journal de bord

```
Date : [date]
Utilisateurs créés :
  - alice : [OK/NOK]
  - dev-user : [OK/NOK]

Roles créés :
  - pod-reader : [OK/NOK]
  - secret-reader : [OK/NOK]
  - developer-role : [OK/NOK]

RoleBindings :
  - read-pods : [OK/NOK]
  - read-secrets : [OK/NOK]
  - developer-binding : [OK/NOK]

Tests de permissions :
  - Alice peut lire pods : [OK/NOK]
  - Alice ne peut pas créer pods : [OK/NOK]
  - Alice ne peut pas voir secrets : [OK/NOK]
```

---

## 📚 Prochaines étapes

Une fois que :
- ✓ RBAC configuré
- ✓ Permissions testées
- ✓ Utilisateurs créés

**Passez à : `09_helm.md`** pour automatiser les déploiements avec Helm.

---

**✅ RBAC est configuré ! Passons à Helm.**
