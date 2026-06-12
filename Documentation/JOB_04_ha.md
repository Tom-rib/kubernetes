# JOB 04 — Haute Disponibilité (Replicas & Self-Healing)

**Objectif** : Implémenter la HA avec replicas, load balancing automatique et test de panne.

**Durée estimée** : 15 minutes  
**Prérequis** : JOB 03 complété

---

## 🎯 Concepts HA

| Concept | Rôle |
|---------|------|
| **Replicas** | N copies d'un pod pour la redondance |
| **ReplicaSet** | Garantit que N pods tournent en permanence |
| **Deployment** | Gère les replicas et les mises à jour |
| **Service** | Load balance automatique sur les replicas |
| **Self-healing** | K3S recrée les pods qui crashent |

---

## 🚀 Étape 1 : Activer les Replicas (Nginx)

### Éditer nginx-deployment.yaml

```yaml
spec:
  replicas: 3  # Passer de 1 à 3
```

### Appliquer la modification

```bash
sudo k3s kubectl apply -f nginx-deployment.yaml
```

### Vérifier la création des replicas

```bash
# Attendre quelques secondes
sudo k3s kubectl get pods | grep nginx

# Doit afficher 3 pods Nginx
NAME                    READY   STATUS    RESTARTS   AGE
nginx-6d4cf56db-abc12   1/1     Running   0          10s
nginx-6d4cf56db-def34   1/1     Running   0          5s
nginx-6d4cf56db-ghi56   1/1     Running   0          2s
```

### Vérifier le ReplicaSet

```bash
sudo k3s kubectl get rs | grep nginx

# Output:
NAME                  DESIRED   CURRENT   READY   AGE
nginx-6d4cf56db      3         3         3       1m
```

---

## 🚀 Étape 2 : Répliquer Apache et MariaDB

```bash
# Éditer apache-deployment.yaml
spec:
  replicas: 2

# Éditer mariadb-deployment.yaml
spec:
  replicas: 1  # Les BD stateful restent en 1 (voir JOB 05)
```

Appliquer :

```bash
sudo k3s kubectl apply -f apache-deployment.yaml
sudo k3s kubectl apply -f mariadb-deployment.yaml

# Vérifier
sudo k3s kubectl get pods
```

---

## 🧪 Étape 3 : Test de Self-Healing

### Test 1 : Supprimer un Pod

```bash
# Récupérer le nom d'un pod Nginx
POD_NAME=$(sudo k3s kubectl get pods | grep nginx | head -1 | awk '{print $1}')

# Supprimer le pod
sudo k3s kubectl delete pod $POD_NAME

# Observer : K3S en recrée un automatiquement
watch sudo k3s kubectl get pods | grep nginx
```

**Résultat attendu** : Le pod supprimé est remplacé en quelques secondes par un nouveau.

### Test 2 : Tester le Load Balancing

```bash
# Lancer 10 requêtes HTTP
for i in {1..10}; do
  echo "Requête $i:"
  curl http://192.168.1.11:30080 -I | grep Server
done
```

Chaque requête peut être traitée par un pod différent (transparente pour le client).

### Test 3 : Simuler la Panne d'un Nœud

```bash
# Sur l'un des nœuds (workers)
# Identifier quel nœud exécute les pods Nginx
sudo k3s kubectl get pods -o wide | grep nginx

# Noter le nœud (kubes-02 ou kubes-03)

# Se connecter au nœud et l'arrêter :
ssh kubes-02.local
sudo shutdown -r now  # Redémarrage (ou halt)
```

**Observer** :
- Les pods sur kubes-02 passer à `Terminating` puis `Pending`
- Le Service continuer à router vers les pods des autres nœuds
- Après ~1 min, les pods être reschedules sur kubes-03

```bash
# Depuis le master
watch sudo k3s kubectl get pods -o wide
```

---

## 📊 Vérification Complète (JOB 04)

```bash
# 1. Vérifier les replicas
sudo k3s kubectl get deployments
# Doit afficher replicas: 3 pour nginx, 2 pour apache

# 2. Vérifier les pods
sudo k3s kubectl get pods -o wide
# Doit afficher distribués sur les 3 nœuds

# 3. Vérifier les ReplicaSets
sudo k3s kubectl get rs

# 4. Vérifier les événements
sudo k3s kubectl get events --sort-by='.lastTimestamp'

# 5. Test du Service (load balancing)
for i in {1..5}; do
  sudo k3s kubectl get svc
done
```

---

## 🔄 Stratégies de Déploiement

### RollingUpdate (par défaut)

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max 1 pod supplémentaire pendant l'update
      maxUnavailable: 0  # Pas de downtime
```

### Recreate (simple, avec downtime)

```yaml
spec:
  strategy:
    type: Recreate
```

---

## 📝 Dépannage JOB 04

| Problème | Solution |
|----------|----------|
| Pods restent `Pending` | Pas de ressources → `kubectl describe pod` |
| Pods en `CrashLoopBackOff` | Erreur dans le conteneur → `kubectl logs` |
| Load balancing pas équilibré | Normal, c'est probabiliste. Refaire le test |
| Nœud reste `NotReady` après reboot | Relancer K3S: `sudo systemctl restart k3s` |

---

## ✅ Prêt pour JOB 05 ?

```bash
# Vérifier:
sudo k3s kubectl get deployments | grep -E 'nginx|apache|mariadb'

# Doit afficher:
# nginx       3/3     3            3           5m
# apache      2/2     2            2           5m
```

→ **Suivant** : [JOB 05 — Stockage Persistant](./JOB_05_volumes.md)

**Notes de l'étudiant** :
```
- Replicas Nginx: ☐  Apache: ☐
- Self-healing testé: ☐
- Nœud reboté et pods reschedules: ☐
- Observations: ___
```
