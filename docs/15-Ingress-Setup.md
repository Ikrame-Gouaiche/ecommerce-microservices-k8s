# Configuration Ingress pour E-commerce Application

## Vue d'ensemble

L'Ingress permet d'exposer les services de l'application via un seul point d'entrée avec le nom de domaine **ensa.com**.

## Architecture

```
                                Internet
                                   |
                            ensa.com (DNS)
                                   |
                            [Ingress Controller]
                                   |
                    +---------------+---------------+
                    |               |               |
                  [UI]          [Zuul]      [Microservices]
                 :8080          :9999         :1001-1004
```

## Configuration

### 1. Prérequis

#### Installer Nginx Ingress Controller

```bash
# Pour Minikube
minikube addons enable ingress

# Vérifier l'installation
kubectl get pods -n ingress-nginx

# Pour Kubernetes standard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### 2. Configuration DNS

Ajouter l'entrée DNS pour ensa.com dans `/etc/hosts` :

```bash
# Obtenir l'IP de Minikube
minikube ip

# Ajouter dans /etc/hosts (remplacer <MINIKUBE_IP> par l'IP obtenue)
sudo bash -c 'echo "<MINIKUBE_IP> ensa.com" >> /etc/hosts'

# Exemple:
# 192.168.49.2 ensa.com
```

### 3. Déployer l'Application avec Ingress

```bash
# Déployer avec Ingress activé (par défaut)
helm install ecommerce ./helm-charts/ecommerce-app

# Ou spécifier explicitement
helm install ecommerce ./helm-charts/ecommerce-app \
  --set ingress.enabled=true

# Vérifier l'Ingress
kubectl get ingress
```

### 4. Routes Configurées

| Path | Service | Port | Description |
|------|---------|------|-------------|
| `/` | ui | 8080 | Interface utilisateur React |
| `/api/offers` | offers | 1001 | Service des offres |
| `/api/shoes` | shoe | 1002 | Service des chaussures |
| `/api/cart` | cart | 1004 | Service du panier |
| `/api/wishlist` | wishlist | 1003 | Service des favoris |
| `/api` | zuul | 9999 | API Gateway (fallback) |

## Utilisation

### Accéder à l'Application

```bash
# Interface Web
http://ensa.com

# API Offers
curl http://ensa.com/api/offers

# API Shoes
curl http://ensa.com/api/shoes

# API Cart
curl http://ensa.com/api/cart

# API Wishlist
curl http://ensa.com/api/wishlist
```

### Vérifier la Configuration

```bash
# Voir les détails de l'Ingress
kubectl describe ingress ecommerce-ingress

# Voir les logs du contrôleur Ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Tester la résolution DNS
nslookup ensa.com
ping ensa.com
```

## Configuration Avancée

### Activer TLS/HTTPS

1. **Modifier values.yaml** :

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: ensa.com
      paths:
        - path: /
          pathType: Prefix
          serviceName: ui
          servicePort: 8080
  tls:
    - secretName: ensa-tls
      hosts:
        - ensa.com
```

2. **Installer cert-manager** :

```bash
# Ajouter le repo cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Installer cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

3. **Créer un ClusterIssuer** :

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: votre-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Personnaliser les Annotations

```yaml
ingress:
  annotations:
    # Redirection HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    # Taille maximale du body
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    
    # Timeout
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
```

## Désactiver l'Ingress

Si vous préférez utiliser NodePort ou LoadBalancer :

```bash
# Déployer sans Ingress
helm install ecommerce ./helm-charts/ecommerce-app \
  --set ingress.enabled=false

# Mettre à jour pour désactiver Ingress
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set ingress.enabled=false
```

## Dépannage

### Problème 1: Ingress non accessible

```bash
# Vérifier que l'Ingress Controller est actif
kubectl get pods -n ingress-nginx

# Vérifier l'Ingress
kubectl get ingress
kubectl describe ingress ecommerce-ingress

# Vérifier les services backend
kubectl get svc
```

### Problème 2: DNS ne résout pas

```bash
# Vérifier /etc/hosts
cat /etc/hosts | grep ensa.com

# Vider le cache DNS
sudo systemd-resolve --flush-caches

# Tester avec l'IP directement
curl http://$(minikube ip) -H "Host: ensa.com"
```

### Problème 3: 404 Not Found

```bash
# Vérifier les règles Ingress
kubectl get ingress ecommerce-ingress -o yaml

# Vérifier que les services existent
kubectl get svc ui offers shoe cart wishlist zuul

# Tester un service directement
kubectl port-forward svc/ui 8080:8080
curl http://localhost:8080
```

### Problème 4: 502 Bad Gateway

```bash
# Vérifier que les pods sont en Running
kubectl get pods

# Vérifier les logs des pods
kubectl logs <pod-name>

# Vérifier les endpoints
kubectl get endpoints
```

## Exemples de Tests

### Test Complet

```bash
#!/bin/bash

echo "=== Test de l'Ingress ensa.com ==="

# Test UI
echo "Test UI (/):"
curl -s http://ensa.com | head -n 5

# Test API Offers
echo -e "\nTest API Offers (/api/offers):"
curl -s http://ensa.com/api/offers

# Test API Shoes
echo -e "\nTest API Shoes (/api/shoes):"
curl -s http://ensa.com/api/shoes

# Test API Cart
echo -e "\nTest API Cart (/api/cart):"
curl -s http://ensa.com/api/cart

# Test API Wishlist
echo -e "\nTest API Wishlist (/api/wishlist):"
curl -s http://ensa.com/api/wishlist

echo -e "\n=== Tests terminés ==="
```

### Test de Charge

```bash
# Installer Apache Bench
sudo apt-get install apache2-utils

# Test de charge sur UI
ab -n 1000 -c 10 http://ensa.com/

# Test de charge sur API
ab -n 1000 -c 10 http://ensa.com/api/offers
```

## Configuration Production

Pour un environnement de production :

```yaml
# values-prod.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/limit-rps: "100"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: www.ensa.com
      paths:
        - path: /
          pathType: Prefix
          serviceName: ui
          servicePort: 8080
    - host: api.ensa.com
      paths:
        - path: /
          pathType: Prefix
          serviceName: zuul
          servicePort: 9999
  tls:
    - secretName: ensa-tls
      hosts:
        - www.ensa.com
        - api.ensa.com
```

## Monitoring

```bash
# Métriques Ingress
kubectl top pods -n ingress-nginx

# Logs en temps réel
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Statistiques Nginx
kubectl exec -n ingress-nginx <ingress-pod> -- nginx -T
```

## Résumé

✅ Ingress configuré avec le domaine **ensa.com**  
✅ Routes pour tous les microservices  
✅ Support TLS/HTTPS (optionnel)  
✅ Annotations personnalisables  
✅ Compatible Minikube et Kubernetes standard  

L'Ingress simplifie l'accès à l'application en fournissant un seul point d'entrée au lieu de multiples NodePorts.
