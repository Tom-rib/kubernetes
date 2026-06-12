# JOB 05 — Stockage Persistant (PV & PVC)

**Objectif** : Configurer le stockage persistant pour MariaDB et Nginx.

**Durée estimée** : 20 minutes  
**Prérequis** : JOB 04 complété

---

## 🎯 Concepts

| Objet | Rôle |
|-------|------|
| **StorageClass** | Définit les types de stockage disponibles |
| **PersistentVolume** | Ressource de stockage cluster-wide |
| **PersistentVolumeClaim** | Demande de stockage par une application |
| **volumeMounts** | Point de montage dans le conteneur |

---

## 🚀 Étape 1 : Vérifier la StorageClass par Défaut

K3S fournit une StorageClass `local-path` par défaut :

```bash
sudo k3s kubectl get sc

# Output:
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer
```

---

## 🚀 Étape 2 : Créer une PVC pour MariaDB

### Créer `mariadb-pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-backup
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 2Gi
```

### Appliquer la PVC

```bash
sudo k3s kubectl apply -f mariadb-pvc.yaml

# Vérifier
sudo k3s kubectl get pvc
```

---

## 🔧 Étape 3 : Modifier le Deployment MariaDB

### Éditer `mariadb-deployment.yaml`

Ajouter les volumes :

```yaml
spec:
  template:
    spec:
      containers:
      - name: mariadb
        # ... reste inchangé ...
        volumeMounts:
        - name: mariadb-data
          mountPath: /var/lib/mysql
        - name: mariadb-backup
          mountPath: /backup
      volumes:
      - name: mariadb-data
        persistentVolumeClaim:
          claimName: mariadb-data
      - name: mariadb-backup
        persistentVolumeClaim:
          claimName: mariadb-backup
```

### Réappliquer le manifest

```bash
sudo k3s kubectl apply -f mariadb-deployment.yaml

# Attendre que le pod se redémarre
sudo k3s kubectl get pods | grep mariadb
```

### Vérifier le montage

```bash
# Se connecter au pod
sudo k3s kubectl exec -it deployment/mariadb -- ls -la /var/lib/mysql

# Doit afficher les fichiers de la BD
```

---

## 🚀 Étape 4 : Créer une PVC pour Nginx (logs)

### Créer `nginx-pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-logs
spec:
  accessModes:
    - ReadWriteMany  # Plusieurs pods peuvent lire/écrire
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

### Appliquer et modifier Nginx

```bash
sudo k3s kubectl apply -f nginx-pvc.yaml

# Éditer nginx-deployment.yaml
# Ajouter dans volumeMounts:
volumeMounts:
- name: logs
  mountPath: /var/log/nginx

# Dans volumes:
volumes:
- name: logs
  persistentVolumeClaim:
    claimName: nginx-logs
```

---

## 🧪 Étape 5 : Test de Persistance

### Test 1 : Données persistantes après pod restart

```bash
# Écrire quelque chose dans MariaDB
sudo k3s kubectl exec -it deployment/mariadb -- mysql -u root -prootpass -e \
  "CREATE TABLE test (id INT, msg TEXT); \
   INSERT INTO test VALUES (1, 'K3S HA TEST');"

# Supprimer le pod
POD=$(sudo k3s kubectl get pod -l app=mariadb -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl delete pod $POD

# Attendre le redémarrage
sleep 10

# Vérifier que les données sont toujours là
sudo k3s kubectl exec -it deployment/mariadb -- mysql -u root -prootpass -e \
  "SELECT * FROM test;"

# Doit afficher : 1 | K3S HA TEST
```

### Test 2 : Vérifier l'existence du PV

```bash
sudo k3s kubectl get pv

# Doit afficher:
# pvc-xxxxx        5Gi        RWO            Delete           Bound
```

---

## 📊 Vérification Complète (JOB 05)

```bash
# 1. PVCs créées
sudo k3s kubectl get pvc

# 2. PVs liés
sudo k3s kubectl get pv

# 3. Pod MariaDB avec volumeMounts
sudo k3s kubectl describe pod -l app=mariadb | grep -A 5 "Mounts:"

# 4. Test de lecture/écriture
sudo k3s kubectl exec -it deployment/mariadb -- ls -la /var/lib/mysql

# 5. Vérifier la taille utilisée
sudo k3s kubectl exec -it deployment/mariadb -- du -sh /var/lib/mysql
```

---

## 📝 Dépannage JOB 05

| Problème | Solution |
|----------|----------|
| PVC reste `Pending` | StorageClass pas dispo → `kubectl get sc` |
| Pod ne démarre pas | Impossible de monter la PVC → `kubectl describe pvc` |
| Permission denied sur le volume | User/permission du conteneur → vérifier securityContext |

---

## 🗄️ Types d'Accès (accessModes)

| Mode | Signification | Cas d'usage |
|------|---------------|-----------|
| `ReadWriteOnce` | 1 nœud peut lire/écrire | BD, stateful |
| `ReadOnlyMany` | Plusieurs nœuds lisent | Configs partageées |
| `ReadWriteMany` | Plusieurs nœuds lisent/écrivent | Logs, cache partagé |

---

## ✅ Prêt pour JOB 06 ?

```bash
# Vérifier:
sudo k3s kubectl get pvc | grep -E 'mariadb|nginx'
# Doit afficher 3 PVCs en Bound
```

→ **Suivant** : [JOB 06 — ConfigMaps](./JOB_06_configmaps.md)

**Notes de l'étudiant** :
```
- PVCs créées pour MariaDB: ☐
- PVCs créées pour Nginx: ☐
- Volumes montés: ☐
- Test de persistance OK: ☐
```
