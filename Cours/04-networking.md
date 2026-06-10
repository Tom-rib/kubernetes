# 🌐 Cours 04 - Networking Kubernetes (2 heures)

## 📚 Table des matières
1. [Concepts réseau](#concepts)
2. [Services](#services)
3. [DNS](#dns)
4. [Ingress](#ingress)
5. [Network Policies](#network-policies)
6. [Résumé](#résumé)

---

## 🎯 Concepts Réseau

### Architecture réseau K8s

```
External
   ↓
LoadBalancer (Ingress Controller)
   ↓ (Layer 7 : HTTP/HTTPS)
Service (Layer 4 : TCP/UDP)
   ↓
Pods (avec IP uniques)
   ↓
Conteneurs
```

### IP dans Kubernetes

```
Pod IP : 10.244.x.x (éphémère)
├─ Change à chaque redémarrage
├─ Unique dans le cluster
└─ Ne pas compter dessus !

Service IP : 10.43.x.x (stable)
├─ Reste même si pods changent
├─ Load balance vers pods
└─ À utiliser !

Node IP : 192.168.1.x (machine)
├─ IP physique du nœud
└─ Pour NodePort
```

---

## 🔌 Services

### Rappel des types

#### ClusterIP (Interne)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP  # Défaut
  selector:
    app: nginx
  ports:
  - port: 80           # Port du service
    targetPort: 8080   # Port du pod
```

**Accès** :
```
Pod A → http://nginx-service (DNS interne)
     → http://nginx-service.default.svc.cluster.local (FQDN)
     → IP : 10.43.0.100
```

**Iptables sur le nœud** :
```
iptables -L -n | grep 10.43.0.100
-A KUBE-SERVICES -d 10.43.0.100/32 -j KUBE-SVC-... -m comment --comment "default/nginx-service:80"
```

#### NodePort

```yaml
spec:
  type: NodePort
  ports:
  - port: 80           # Service port
    targetPort: 8080   # Pod port
    nodePort: 30080    # Node port (30000-32767)
```

**Accès** :
```
External
  ↓ (tcp:30080)
Node IP:30080 (192.168.1.101:30080)
  ↓ (iptables forward)
Service (10.43.0.100:80)
  ↓ (load-balance)
Pod (10.244.x.x:8080)
```

**Tous les nœuds ont le port** :
```
Node 1:30080 → Service
Node 2:30080 → Service (même si pas de pod ici)
Node 3:30080 → Service
```

#### LoadBalancer

```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
```

**Accès** :
```
Internet (50.1.2.3:80)
  ↓ (LB distribue)
Nodes:NodePort
  ↓
Service
  ↓
Pods
```

**Nécessite** :
- Cloud provider (AWS, GCP, Azure, etc.)
- Ou MetalLB en on-premise

#### ExternalName

```yaml
spec:
  type: ExternalName
  externalName: external-db.example.com
```

**Accès** :
```
Pod A → http://my-db
     → CNAME : external-db.example.com
     → DNS externe résout IP
```

### Service Selectors

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
    tier: frontend
  ports:
  - port: 80
```

**Sélectionne les pods avec TOUS les labels** :
```
app: myapp
tier: frontend
```

---

## 🔍 DNS Interne

### Noms de services

```
Service DNS Resolution

<service-name>
├─ Même namespace
├─ Résout à : 10.43.x.x
└─ Exemple : curl http://nginx-service

<service-name>.<namespace>
├─ Namespace spécifique
├─ Résout à : 10.43.x.x
└─ Exemple : curl http://nginx-service.default

<service-name>.<namespace>.svc.cluster.local
├─ FQDN complet
├─ Résout à : 10.43.x.x
└─ Exemple : curl http://nginx-service.default.svc.cluster.local
```

### CoreDNS

**Service DNS dans K8s** :
```
Pod → CoreDNS (10.43.0.10:53)
    → Résout noms Kubernetes
    → Résout noms externes
```

**Config CoreDNS** :
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
      errors
      health
      kubernetes cluster.local in-addr.arpa ip6.arpa {  # K8s domains
        pods insecure
        upstream 1.1.1.1
        fallthrough in-addr.arpa ip6.arpa
      }
      prometheus :9153
      proxy . 8.8.8.8  # Google DNS
    }
```

### Tester la résolution DNS

```bash
# Depuis un pod
kubectl exec -it nginx-pod -- nslookup nginx-service
kubectl exec -it nginx-pod -- nslookup mysql-service.production
kubectl exec -it nginx-pod -- dns resolution check

# Vérifier CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

---

## 🚪 Ingress

### Qu'est-ce qu'une Ingress ?

**Ingress** = Routeur HTTP/HTTPS au niveau application

```
HTTP/HTTPS (port 80/443)
  ↓
Ingress Controller (nginx, Traefik, etc.)
  ↓ (Layer 7 : HTTP)
Routes :
├─ Host-based : api.example.com → api-service
├─ Path-based : /api → api-service
│             : /web → web-service
└─ TLS : Certificats SSL/TLS
  ↓
Services
  ↓
Pods
```

### Exemple Ingress basique

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Accès** :
```
curl http://example.com
  → Ingress détecte host : example.com
  → Route vers web-service
  → Load-balance vers web pods
```

### Ingress avec TLS

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: secure-tls
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Auto-HTTPS** :
```
cert-manager
├─ Détecte l'Ingress
├─ Demande certificat Let's Encrypt
├─ Crée secret TLS
└─ Ingress controller utilise cert
```

### Ingress Controllers

#### nginx-ingress

```bash
# Installer
helm install nginx-ingress nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

#### Traefik (K3S inclus)

```bash
# Déjà installé dans K3S
kubectl get pods -n kube-system | grep traefik
```

#### Autres

```
├─ HAProxy Ingress Controller
├─ Apache Ingress Controller
├─ AWS ALB Controller
└─ Google Cloud Load Balancing
```

### Routing basé sur le chemin

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
spec:
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /static
        pathType: Prefix
        backend:
          service:
            name: cdn-service
            port:
              number: 3000
```

**Résultat** :
```
myapp.com/api → api-service
myapp.com/web → web-service
myapp.com/static → cdn-service
```

---

## 🔐 Network Policies

### Concept : Pare-feu pour pods

```
Par défaut : Tous les pods peuvent communiquer

NetworkPolicy
└─ Isoler les pods
├─ Permettre trafic spécifique
├─ Blocage par défaut
└─ Whitelist (allowlist)
```

### Bloquer tout le trafic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}  # S'applique à tous les pods
  policyTypes:
  - Ingress
  - Egress
```

**Effet** : Aucun trafic entrant/sortant

### Autoriser du trafic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-app
spec:
  podSelector:
    matchLabels:
      app: database  # S'applique aux pods database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend  # Autoriser depuis pods backend
    ports:
    - protocol: TCP
      port: 5432
```

**Effet** :
```
backend pods → TCP:5432 → database pods ✓
frontend pods → TCP:5432 → database pods ✗
External → TCP:5432 → database pods ✗
```

### Autoriser vers un service externe

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-api
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: external  # Vers namespace external
    ports:
    - protocol: TCP
      port: 443
```

---

## 📊 Debugging Réseau

### Vérifier la connectivité

```bash
# Depuis un pod
kubectl exec -it nginx-pod -- ping web-service
kubectl exec -it nginx-pod -- nc -zv web-service 80

# Vérifier DNS
kubectl exec -it nginx-pod -- nslookup web-service

# Vérifier les règles iptables
kubectl debug node/node-1 -it --image=ubuntu
iptables -L -n | grep SERVICE-IP
```

### Logs du Service

```bash
# Service n'a pas de logs
# Mais on peut voir les endpoints

kubectl get endpoints web-service
# Output : IP des pods liés
```

### Service ne fonctionne pas ?

```
Checklist :
├─ Labels selector match ? (kubectl get pods --show-labels)
├─ Port targetPort correct ? (kubectl get svc -o yaml)
├─ Port pod correct ? (kubectl logs pod)
├─ Pod prêt (Ready) ? (kubectl get pods)
└─ Firewall/NetworkPolicy bloque ? (kubectl get networkpolicies)
```

---

## 📋 Résumé

### Types de Services

| Type | Interne | IP stable | External |
|------|---------|-----------|----------|
| ClusterIP | ✓ | ✓ | ✗ |
| NodePort | ✓ | ✓ | ✓ (Node IP) |
| LoadBalancer | ✓ | ✓ | ✓ (LB IP) |
| ExternalName | ✓ | N/A | (DNS externe) |

### DNS Kubernetes

```
<service>.<namespace>.svc.cluster.local
```

### Ingress

```
HTTP/HTTPS → Ingress Controller → Services → Pods
```

### Network Policies

```
Bloquer par défaut → Autoriser spécifiquement
```

---

## 🧪 Quiz d'auto-évaluation

- [ ] Je sais les types de Services
- [ ] Je comprends DNS interne
- [ ] Je peux créer une Ingress
- [ ] Je comprends les basiques de NetworkPolicy
- [ ] Je peux troubleshooter la connectivité

**Si tout est coché, vous maîtrisez le networking K8s !** ✅

---

## 📚 Pour approfondir

- Pratiquer : Créer Services et Ingress
- Lire : https://kubernetes.io/docs/concepts/services-networking/
- Tester : Network policies dans votre cluster

---

*Fin du cours 04. Vous savez exposer vos applications ! 🌐*
