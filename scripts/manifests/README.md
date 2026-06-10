# Manifests Kubernetes

Ce dossier contient les fichiers YAML pour déployer l'infrastructure K3S.

## Fichiers

### Déploiements individuels
- **01-nginx-deployment.yaml** : Nginx avec HA (3 replicas) et volumes persistants
- **02-mariadb-deployment.yaml** : MariaDB avec HA (2 replicas), volumes et secrets
- **03-apache-deployment.yaml** : Apache avec HA (2 replicas)

### Déploiement groupé
- **all-in-one.yaml** : Tous les déploiements ensemble

## Utilisation

### Déployer tout d'un coup
```bash
kubectl apply -f all-in-one.yaml
```

### Déployer individuellement
```bash
kubectl apply -f 01-nginx-deployment.yaml
kubectl apply -f 02-mariadb-deployment.yaml
kubectl apply -f 03-apache-deployment.yaml
```

### Vérifier l'état
```bash
kubectl get pods -n apps
kubectl get svc -n apps
kubectl get pvc -n apps
```

### Supprimer les déploiements
```bash
kubectl delete -f all-in-one.yaml
```

## Prérequis

Avant d'appliquer les manifests, créez les répertoires de stockage sur chaque nœud :

```bash
# Sur chaque nœud (kubes-01, 02, 03)
mkdir -p /mnt/storage/nginx
mkdir -p /mnt/storage/mariadb
chmod 777 /mnt/storage/nginx
chmod 777 /mnt/storage/mariadb
```

## Notes

- Les manifests créent automatiquement le namespace "apps"
- Les secrets sont définis en clair dans les fichiers YAML (à sécuriser en prod)
- Les volumes sont en hostPath (ok pour dev, utiliser des StorageClass en prod)
- La réplication MariaDB est limitée à 1 (ReadWriteOnce - utiliser Galera pour +1)

## Personnalisation

Vous pouvez modifier les replicas, images, ressources, etc. dans les fichiers YAML avant de les appliquer.

Exemple : changer le nombre de replicas nginx
```yaml
spec:
  replicas: 5  # Au lieu de 3
```

Puis appliquer :
```bash
kubectl apply -f 01-nginx-deployment.yaml
```

Kubernetes mettra à jour automatiquement le déploiement.
