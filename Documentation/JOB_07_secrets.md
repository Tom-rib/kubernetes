# JOB 07 — Secrets (Données Sensibles)

**Objectif** : Stocker et gérer les données sensibles (mots de passe, tokens) de manière sécurisée.

**Durée estimée** : 15 minutes  
**Prérequis** : JOB 06 complété

---

## 🎯 Concepts

**Secret** = données sensibles chiffrées en etcd (au repos).

**Types** :
- `Opaque` : chaînes base64 (défaut)
- `kubernetes.io/basic-auth` : username + password
- `kubernetes.io/docker-cfg` : credentials Docker
- `kubernetes.io/tls` : certificats TLS

---

## 🚀 Étape 1 : Créer un Secret pour MariaDB

### Créer `mariadb-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-credentials
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "SecureRootPass123!"
  MYSQL_USER: "appuser"
  MYSQL_PASSWORD: "AppPass456!"
  DATABASE: "appdb"
```

**Ou créer avec kubectl** :

```bash
# Créer manuellement (puis copier-coller dans YAML)
sudo k3s kubectl create secret generic mariadb-credentials \
  --from-literal=MYSQL_ROOT_PASSWORD="SecureRootPass123!" \
  --from-literal=MYSQL_USER="appuser" \
  --from-literal=MYSQL_PASSWORD="AppPass456!" \
  --from-literal=DATABASE="appdb" \
  --dry-run=client -o yaml > mariadb-secret.yaml
```

### Appliquer le Secret

```bash
sudo k3s kubectl apply -f mariadb-secret.yaml

# Vérifier (ne montre pas les valeurs)
sudo k3s kubectl get secret
sudo k3s kubectl describe secret mariadb-credentials
```

---

## 🔧 Étape 2 : Utiliser le Secret dans MariaDB Deployment

### Éditer `mariadb-deployment.yaml`

```yaml
spec:
  template:
    spec:
      containers:
      - name: mariadb
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: MYSQL_PASSWORD
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mariadb-credentials
              key: DATABASE
```

### Réappliquer le Deployment

```bash
sudo k3s kubectl apply -f mariadb-deployment.yaml

# Vérifier que le pod redémarre
sudo k3s kubectl get pods | grep mariadb
```

---

## 🚀 Étape 3 : Secret TLS (Certificat HTTPS)

### Créer un certificat auto-signé

```bash
# Générer une clé privée
openssl genrsa -out tls.key 2048

# Générer un CSR
openssl req -new -key tls.key -out tls.csr \
  -subj "/CN=nginx.local"

# Auto-signer le certificat
openssl x509 -req -days 365 -in tls.csr \
  -signkey tls.key -out tls.crt
```

### Créer le Secret TLS

```bash
sudo k3s kubectl create secret tls nginx-tls \
  --cert=tls.crt \
  --key=tls.key

# Vérifier
sudo k3s kubectl get secret nginx-tls
```

### Utiliser le Secret dans Nginx (avancé)

Pour exposer HTTPS, il faudrait un Ingress (voir extensions).

---

## 🧪 Étape 4 : Test du Secret

### Vérifier les variables d'environnement dans le pod

```bash
# Récupérer le pod MariaDB
POD=$(sudo k3s kubectl get pod -l app=mariadb -o jsonpath='{.items[0].metadata.name}')

# Vérifier que les vars d'env sont présentes (masquées)
sudo k3s kubectl exec -it $POD -- env | grep MYSQL
```

### Tester la connexion avec les credentials du Secret

```bash
# Connexion au conteneur MariaDB
sudo k3s kubectl exec -it $POD -- mysql -u appuser -pAppPass456! -e "SHOW DATABASES;"

# Doit afficher les BDs de appuser (pas juste test_db)
```

---

## 🔒 Étape 5 : Décoder un Secret (audit)

⚠️ **Important** : Les Secrets ne sont que base64 (pas chiffré par défaut) !

```bash
# Voir le contenu brut (base64)
sudo k3s kubectl get secret mariadb-credentials -o yaml

# Décoder une clé
sudo k3s kubectl get secret mariadb-credentials -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 -d

# Output: SecureRootPass123!
```

**Pour du chiffrement réel** : voir `--encryption-provider-config` (étape avancée).

---

## 📊 Vérification Complète (JOB 07)

```bash
# 1. Secrets créés
sudo k3s kubectl get secret

# 2. Contenu du Secret (masqué)
sudo k3s kubectl describe secret mariadb-credentials

# 3. Pod MariaDB utilise le Secret
sudo k3s kubectl exec -it deployment/mariadb -- env | grep MYSQL_

# 4. Test de connexion
sudo k3s kubectl exec -it deployment/mariadb -- \
  mysql -u appuser -pAppPass456! -e "SELECT USER();"
```

**Résultat attendu** :
```
USER()
appuser@%
```

---

## 📝 Dépannage JOB 07

| Problème | Solution |
|----------|----------|
| Mot de passe mal reconnu | Vérifier quotes et échappement dans YAML |
| Pod ne démarre pas | Secret non trouvé → `kubectl describe pod` |
| `secretKeyRef` non trouvée | Vérifier le nom et la clé du Secret |

---

## ⚠️ Bonnes Pratiques

- ✅ Stocker les Secrets dans un gestionnaire externe (Vault, AWS Secrets)
- ✅ Chiffrer les Secrets en etcd
- ✅ Limiter l'accès RBAC aux Secrets
- ✅ Audit les accès aux Secrets

---

## ✅ Prêt pour JOB 08 ?

```bash
sudo k3s kubectl get secret | grep -E 'mariadb|nginx'
# Doit afficher au moins 2 secrets
```

→ **Suivant** : [JOB 08 — RBAC & Sécurité](./JOB_08_rbac.md)

**Notes de l'étudiant** :
```
- Secret MariaDB créé: ☐
- Secret TLS créé: ☐
- Variables env vérifiées: ☐
- Connexion MariaDB avec credentials: ☐
```
