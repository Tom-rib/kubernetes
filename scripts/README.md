# Scripts d'Automatisation K3S

Ce dossier contient les scripts bash pour automatiser le déploiement et la gestion du cluster K3S.

## 📋 Liste des Scripts

### 1. **01_setup_vms.sh** - Configuration des VMs
**Usage** : Exécuter sur chaque VM Debian avant K3S

```bash
chmod +x 01_setup_vms.sh
sudo ./01_setup_vms.sh
```

**Tâches automatisées** :
- ✓ Mise à jour du système
- ✓ Désactivation du swap
- ✓ Configuration des modules kernel
- ✓ Configuration sysctl
- ✓ Ouverture des ports firewall
- ✓ Installation des dépendances

**Prérequis** : Accès root sur les VMs

---

### 2. **02_install_k3s.sh** - Installation K3S Master
**Usage** : Exécuter sur le nœud master (kubes-01)

```bash
chmod +x 02_install_k3s.sh
sudo ./02_install_k3s.sh
```

**Tâches automatisées** :
- ✓ Installation de K3S en tant que master
- ✓ Vérification du service K3S
- ✓ Vérification de kubectl
- ✓ Affichage du token du cluster
- ✓ Affichage des commandes pour les workers

**Output** : Token et commande pour rejoindre les workers

---

### 3. **03_join_cluster.sh** - Rejoindre le Cluster
**Usage** : Rejoindre les workers au cluster

```bash
chmod +x 03_join_cluster.sh
sudo ./03_join_cluster.sh [MASTER_IP]
```

**Paramètres** :
- `MASTER_IP` (optionnel) : IP du master (défaut: 192.168.1.101)

**Tâches automatisées** :
- ✓ Récupération du token depuis le master
- ✓ Installation K3S en mode worker sur chaque nœud
- ✓ Attente du démarrage
- ✓ Vérification du cluster

**Output** : Affichage des nœuds du cluster

---

### 4. **04_deploy_apps.sh** - Déployer les Applications
**Usage** : Déployer nginx, apache, mariadb sur le cluster

```bash
chmod +x 04_deploy_apps.sh
./04_deploy_apps.sh
```

**Prérequis** :
- kubectl configuré
- Accès au cluster K3S
- Fichiers manifests dans `./manifests/`

**Tâches automatisées** :
- ✓ Création des répertoires de stockage
- ✓ Création du namespace "apps"
- ✓ Déploiement de Nginx
- ✓ Déploiement d'Apache
- ✓ Déploiement de MariaDB
- ✓ Vérification des pods/services

**Output** :
- URLs d'accès aux applications
- Commandes de debugging
- Commandes de test

---

### 5. **05_test_ha.sh** - Tester la Haute Disponibilité
**Usage** : Valider la HA du cluster

```bash
chmod +x 05_test_ha.sh
./05_test_ha.sh
```

**Tests effectués** :
- ✓ État initial du cluster
- ✓ Redémarrage d'un pod
- ✓ Scalabilité (scale up/down)
- ✓ Continuité de service
- ✓ Santé des nœuds
- ✓ Utilisation des ressources
- ✓ Événements du cluster

**Output** : Résumé des tests et commandes utiles

---

## 🚀 Utilisation Complète (Workflow)

### Étape 1 : Préparation des VMs
```bash
# Sur chaque VM (kubes-01, 02, 03)
scp -r scripts/ root@192.168.1.101:/tmp/
ssh root@192.168.1.101
cd /tmp/scripts
chmod +x 01_setup_vms.sh
./01_setup_vms.sh
reboot
```

### Étape 2 : Installation K3S Master
```bash
# Sur kubes-01
ssh root@192.168.1.101
cd /tmp/scripts
chmod +x 02_install_k3s.sh
./02_install_k3s.sh

# Noter le TOKEN affiché
```

### Étape 3 : Rejoindre les Workers
```bash
# Sur votre machine avec kubectl
chmod +x scripts/03_join_cluster.sh
./scripts/03_join_cluster.sh 192.168.1.101

# Vous devez avoir SSH configuré vers les workers
```

### Étape 4 : Déployer les Applications
```bash
# Sur votre machine avec kubectl
chmod +x scripts/04_deploy_apps.sh
./scripts/04_deploy_apps.sh
```

### Étape 5 : Tester la HA
```bash
# Sur votre machine avec kubectl
chmod +x scripts/05_test_ha.sh
./scripts/05_test_ha.sh
```

---

## 📊 Configuration Réseau (Adapter selon vos IPs)

Les scripts utilisent les IPs par défaut :
```
Master  : 192.168.1.101 (kubes-01)
Worker1 : 192.168.1.102 (kubes-02)
Worker2 : 192.168.1.103 (kubes-03)
```

Pour changer les IPs, éditez les scripts :
```bash
nano 03_join_cluster.sh
# Modifier MASTER_IP et WORKER_IPS
```

---

## 🔒 Prérequis Importants

### Pour tous les scripts
- ✓ Accès root ou sudo
- ✓ SSH configuré entre les machines
- ✓ Connectivité réseau complète

### Pour 03_join_cluster.sh
- ✓ kubectl sur la machine locale
- ✓ kubeconfig correctement configuré
- ✓ SSH root activé sur les workers

### Pour 04_deploy_apps.sh et 05_test_ha.sh
- ✓ kubectl configuré et connecté au cluster
- ✓ Fichiers manifests dans `./manifests/`
- ✓ Permissions pour créer des namespaces

---

## ⚠️ Troubleshooting

### Script ne s'exécute pas
```bash
# Rendre exécutable
chmod +x nom_script.sh

# Exécuter avec bash
bash nom_script.sh
```

### Erreur "Command not found"
```bash
# Installer les dépendances
sudo apt-get update
sudo apt-get install -y curl wget git openssh-client

# Installer kubectl
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### SSH non configuré
```bash
# Configurer SSH sans mot de passe (optionnel)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
ssh-copy-id root@192.168.1.101
ssh-copy-id root@192.168.1.102
ssh-copy-id root@192.168.1.103
```

---

## 📝 Personnalisation

### Modifier le nombre de replicas
```bash
nano 04_deploy_apps.sh
# Chercher "replicaCount" et changer les valeurs
```

### Modifier les IPs
```bash
nano 03_join_cluster.sh
# Chercher "MASTER_IP" et "WORKER_IPS"

nano 04_deploy_apps.sh
# Chercher "MASTER_IP"
```

### Ajouter d'autres applications
```bash
# Ajouter le manifest YAML dans manifests/
# Ajouter dans 04_deploy_apps.sh :
kubectl apply -f manifests/my-new-app.yaml
```

---

## 🎯 Cas d'Usage Typiques

### Déploiement rapide
```bash
./01_setup_vms.sh
./02_install_k3s.sh
./03_join_cluster.sh
./04_deploy_apps.sh
./05_test_ha.sh
```

### Redéploiement complet (reset)
```bash
# Supprimer l'app
kubectl delete -f manifests/all-in-one.yaml

# Redéployer
./04_deploy_apps.sh
```

### Tester la HA après modification
```bash
# Modifier un déploiement
kubectl scale deployment nginx-ha --replicas=10 -n apps

# Tester
./05_test_ha.sh
```

---

## 📚 Commandes Utiles Complémentaires

```bash
# Voir l'état du cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Voir les logs
kubectl logs <pod-name> -n apps
kubectl logs <pod-name> -n apps -f  # Suivi

# Entrer dans un pod
kubectl exec -it <pod-name> -n apps -- /bin/bash

# Voir les events
kubectl get events -n apps

# Vérifier les ressources
kubectl top nodes
kubectl top pods -n apps
```

---

## 🔄 Automatisation Avancée (Optionnel)

### Cron : Tester la HA quotidiennement
```bash
# Ajouter au crontab
crontab -e

# Ajouter :
0 3 * * * /home/user/projet-k3s-kubernetes/scripts/05_test_ha.sh >> /var/log/k3s-test.log 2>&1
```

### Nagios/Monitoring : Vérifier le cluster
```bash
# Wrapper pour monitoring
#!/bin/bash
NODES=$(kubectl get nodes --no-headers | wc -l)
if [ $NODES -lt 3 ]; then
    echo "CRITICAL: Only $NODES nodes available"
    exit 2
else
    echo "OK: All $NODES nodes available"
    exit 0
fi
```

---

## 📞 Support

Si un script échoue :

1. **Vérifier les logs**
   ```bash
   # Logs K3S sur master
   systemctl status k3s
   journalctl -u k3s -n 50
   
   # Logs K3S sur worker
   systemctl status k3s-agent
   journalctl -u k3s-agent -n 50
   ```

2. **Consulter la doc**
   - Voir [Documentation/07_depannage.md](../Documentation/07_depannage.md)
   - Voir [Documentation/08_annexes.md](../Documentation/08_annexes.md)

3. **Tester manuellement**
   ```bash
   # Au lieu d'utiliser le script
   kubectl get pods -n apps
   kubectl describe pod <pod-name> -n apps
   kubectl logs <pod-name> -n apps
   ```

---

## ✨ Bonnes Pratiques

1. **Exécuter les scripts dans l'ordre** : 01 → 02 → 03 → 04 → 05
2. **Attendre la fin** : Chaque script affiche un message de fin
3. **Documenter** : Noter les IPs, tokens, et modifications apportées
4. **Tester** : Exécuter 05_test_ha.sh après chaque déploiement
5. **Sauvegarder** : Copier les logs et configurations importantes

---

*Fin de la documentation des scripts. Bonne automatisation !* 🚀
