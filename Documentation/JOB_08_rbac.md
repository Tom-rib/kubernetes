# JOB 08 — RBAC & Sécurité (Contrôle d'Accès)

**Objectif** : Implémenter le contrôle d'accès basé sur les rôles (RBAC) et durcir le cluster.

**Durée estimée** : 20 minutes  
**Prérequis** : JOB 07 complété

---

## 🎯 RBAC : Concepts

| Objet | Rôle |
|-------|------|
| **ServiceAccount** | Identité pour les pods/users |
| **Role** | Ensemble de permissions (namespace-scoped) |
| **ClusterRole** | Ensemble de permissions (cluster-wide) |
| **RoleBinding** | Assigne un Role à un ServiceAccount |
| **ClusterRoleBinding** | Assigne un ClusterRole à un ServiceAccount |

---

## 🚀 Étape 1 : Créer des ServiceAccounts

### Créer `rbac-setup.yaml`

```yaml
# Service Account pour Nginx
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-sa
  namespace: default
---
# Service Account pour Apache
apiVersion: v1
kind: ServiceAccount
metadata:
  name: apache-sa
  namespace: default
---
# Service Account pour MariaDB
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mariadb-sa
  namespace: default
---
# Service Account pour un admin restreint
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-user
  namespace: default
```

### Appliquer

```bash
sudo k3s kubectl apply -f rbac-setup.yaml

# Vérifier
sudo k3s kubectl get sa
```

---

## 🔐 Étape 2 : Créer des Roles

### Créer `rbac-roles.yaml`

```yaml
# Role pour Nginx : lecture seule sur configmaps
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nginx-reader
spec:
  rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
---
# Role pour Dev : lecture des logs des pods
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-reader
spec:
  rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list"]
---
# Role pour admin local : tout sauf delete
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
spec:
  rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

### Appliquer

```bash
sudo k3s kubectl apply -f rbac-roles.yaml

# Vérifier
sudo k3s kubectl get roles
```

---

## 🔗 Étape 3 : Créer des RoleBindings

### Créer `rbac-bindings.yaml`

```yaml
# Bind nginx-reader à nginx-sa
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nginx-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-reader
subjects:
- kind: ServiceAccount
  name: nginx-sa
  namespace: default
---
# Bind dev-reader à dev-user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev-reader
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: default
---
# Bind namespace-admin à admin SA
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: namespace-admin
subjects:
- kind: ServiceAccount
  name: admin-sa
  namespace: default
```

### Appliquer

```bash
sudo k3s kubectl apply -f rbac-bindings.yaml

# Vérifier
sudo k3s kubectl get rolebindings
```

---

## 🔧 Étape 4 : Assigner ServiceAccounts aux Pods

### Éditer les Deployments

Pour chaque Deployment, ajouter :

```yaml
spec:
  template:
    spec:
      serviceAccountName: nginx-sa  # pour Nginx
      # ou mariadb-sa, apache-sa, etc.
      containers:
      - name: ...
```

### Réappliquer les Deployments

```bash
sudo k3s kubectl apply -f nginx-deployment.yaml
sudo k3s kubectl apply -f apache-deployment.yaml
sudo k3s kubectl apply -f mariadb-deployment.yaml

# Vérifier
sudo k3s kubectl get pods -o jsonpath='{.items[*].spec.serviceAccountName}'
```

---

## 🧪 Étape 5 : Test des Permissions

### Test 1 : Vérifier les permissions

```bash
# Récupérer le token du dev-user
TOKEN=$(sudo k3s kubectl create token dev-user)

# Tester l'accès avec le token
sudo k3s kubectl --token=$TOKEN get pods
# Doit fonctionner (lecture OK)

sudo k3s kubectl --token=$TOKEN delete pod <nom>
# Doit être refusé (delete non autorisé)
```

### Test 2 : Vérifier les permissions du pod

```bash
# Depuis le pod Nginx
sudo k3s kubectl exec -it deployment/nginx -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Le token du pod est chiffré, avec ses permissions restreintes
```

---

## 🛡️ Étape 6 : Sécurité Additionnelle

### Pod Security Standards

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'MustRunAs'
  fsGroup:
    rule: 'MustRunAs'
  readOnlyRootFilesystem: false
```

### NetworkPolicy (Isoler le trafic)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS seulement
```

---

## 📊 Vérification Complète (JOB 08)

```bash
# 1. ServiceAccounts
sudo k3s kubectl get sa

# 2. Roles
sudo k3s kubectl get roles

# 3. RoleBindings
sudo k3s kubectl get rolebindings

# 4. Vérifier que les pods utilisent les SA
sudo k3s kubectl get pods -o jsonpath='{.items[*].spec.serviceAccountName}'

# 5. Audit : qui peut faire quoi?
sudo k3s kubectl auth can-i get pods --as=system:serviceaccount:default:dev-user
# Output: yes

sudo k3s kubectl auth can-i delete pods --as=system:serviceaccount:default:dev-user
# Output: no
```

---

## 📝 Dépannage JOB 08

| Problème | Solution |
|----------|----------|
| `Error: resourcequotas is forbidden` | Permissions RBAC insuffisantes |
| Token invalide | Créer un nouveau token: `kubectl create token <sa>` |
| Pod ne démarre pas | ServiceAccount non trouvé dans le namespace |

---

## ✅ Prêt pour JOB 09 ?

```bash
# Vérifier que RBAC est en place
sudo k3s kubectl get sa,roles,rolebindings | wc -l
# Doit afficher > 10 objets
```

→ **Suivant** : [JOB 09 — Helm & Automatisation](./JOB_09_helm.md)

**Notes de l'étudiant** :
```
- ServiceAccounts créés: ☐
- Roles assignés: ☐
- RoleBindings en place: ☐
- Permissions testées: ☐
```
