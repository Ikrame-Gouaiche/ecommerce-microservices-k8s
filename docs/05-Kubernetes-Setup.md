# Kubernetes Setup

This guide covers setting up a local Kubernetes cluster using Minikube for development and testing.

## What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

### Key Concepts

- **Cluster**: A set of machines (nodes) running containerized applications
- **Node**: A worker machine in Kubernetes (physical or virtual)
- **Pod**: The smallest deployable unit, contains one or more containers
- **Deployment**: Manages a set of identical pods
- **Service**: An abstraction to expose pods as a network service
- **Namespace**: Virtual cluster for isolating resources

## Minikube Setup

### What is Minikube?

Minikube creates a single-node Kubernetes cluster on your local machine, perfect for development and testing.

### Starting Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Start with specific resources
minikube start --driver=docker --cpus=4 --memory=8192

# Start with specific Kubernetes version
minikube start --kubernetes-version=v1.28.0
```

### Expected Output

```
😄  minikube v1.32.0 on Ubuntu 22.04
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4096MB) ...
🐳  Preparing Kubernetes v1.28.0 on Docker 24.0.7 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

### Verify Cluster

```bash
# Check cluster status
minikube status

# Get cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# Check Kubernetes version
kubectl version --short
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.28.0
```

## Kubectl Configuration

### Understanding kubectl

kubectl is the command-line tool for interacting with Kubernetes clusters.

### Basic kubectl Commands

```bash
# Get cluster information
kubectl cluster-info

# View all resources
kubectl get all

# Get nodes
kubectl get nodes

# Get pods
kubectl get pods

# Get services
kubectl get services

# Get deployments
kubectl get deployments

# Describe a resource
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Kubectl Contexts

```bash
# List contexts
kubectl config get-contexts

# Current context
kubectl config current-context

# Switch context
kubectl config use-context minikube

# View config
kubectl config view
```

## Kubernetes Namespaces

Namespaces provide resource isolation within a cluster.

### Create Namespace

```bash
# Create namespace
kubectl create namespace ecommerce

# Or use YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce
EOF

# List namespaces
kubectl get namespaces

# Set default namespace
kubectl config set-context --current --namespace=ecommerce
```

### Working with Namespaces

```bash
# Get resources in specific namespace
kubectl get pods -n ecommerce

# Get all resources in namespace
kubectl get all -n ecommerce

# Delete namespace (and all resources)
kubectl delete namespace ecommerce
```

## Kubernetes Resources

### 1. Pods

Pods are the smallest deployable units in Kubernetes.

```yaml
# pod-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: offers-pod
  namespace: ecommerce
spec:
  containers:
  - name: offers
    image: ecommerce-microservices-k8s-offers:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 1001
```

```bash
# Create pod
kubectl apply -f pod-example.yaml

# Get pods
kubectl get pods -n ecommerce

# Describe pod
kubectl describe pod offers-pod -n ecommerce

# Delete pod
kubectl delete pod offers-pod -n ecommerce
```

### 2. Deployments

Deployments manage replica sets and pods.

```yaml
# deployment-example.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: offers-deployment
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: offers
  template:
    metadata:
      labels:
        app: offers
    spec:
      containers:
      - name: offers
        image: ecommerce-microservices-k8s-offers:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 1001
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
```

```bash
# Create deployment
kubectl apply -f deployment-example.yaml

# Get deployments
kubectl get deployments -n ecommerce

# Scale deployment
kubectl scale deployment offers-deployment --replicas=3 -n ecommerce

# Update image
kubectl set image deployment/offers-deployment offers=offers:v2 -n ecommerce

# Rollout status
kubectl rollout status deployment/offers-deployment -n ecommerce

# Delete deployment
kubectl delete deployment offers-deployment -n ecommerce
```

### 3. Services

Services expose pods to network traffic.

```yaml
# service-example.yaml
apiVersion: v1
kind: Service
metadata:
  name: offers-service
  namespace: ecommerce
spec:
  type: ClusterIP
  selector:
    app: offers
  ports:
  - port: 1001
    targetPort: 1001
    protocol: TCP
```

```bash
# Create service
kubectl apply -f service-example.yaml

# Get services
kubectl get services -n ecommerce

# Describe service
kubectl describe service offers-service -n ecommerce

# Delete service
kubectl delete service offers-service -n ecommerce
```

### Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal cluster IP | Default, internal communication |
| **NodePort** | Exposes service on each node's IP | External access via node IP:port |
| **LoadBalancer** | Cloud provider load balancer | Production external access |
| **ExternalName** | Maps to external DNS | External service integration |

## ConfigMaps and Secrets

### ConfigMaps

Store non-sensitive configuration data.

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: ecommerce
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  API_GATEWAY_URL: "http://zuul:9999"
```

```bash
# Create ConfigMap
kubectl apply -f configmap.yaml

# View ConfigMap
kubectl get configmaps -n ecommerce
kubectl describe configmap app-config -n ecommerce

# Use in deployment
# spec.containers.env:
# - name: APP_ENV
#   valueFrom:
#     configMapKeyRef:
#       name: app-config
#       key: APP_ENV
```

### Secrets

Store sensitive data like passwords and tokens.

```bash
# Create secret from literal
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=secretpass123 \
  -n ecommerce

# Create from file
kubectl create secret generic ssl-cert \
  --from-file=cert.pem \
  --from-file=key.pem \
  -n ecommerce

# View secrets
kubectl get secrets -n ecommerce

# Describe secret (values are hidden)
kubectl describe secret db-credentials -n ecommerce

# View secret data (base64 encoded)
kubectl get secret db-credentials -n ecommerce -o yaml
```

## Resource Management

### Resource Limits and Requests

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

- **Requests**: Guaranteed resources
- **Limits**: Maximum resources allowed

### Resource Units

- **CPU**: `1` = 1 core, `1000m` = 1 core, `500m` = 0.5 core
- **Memory**: `1Gi` = 1 gibibyte, `512Mi` = 512 mebibytes

## Minikube Addons

### Useful Addons

```bash
# List available addons
minikube addons list

# Enable metrics server
minikube addons enable metrics-server

# Enable dashboard
minikube addons enable dashboard

# Enable ingress
minikube addons enable ingress

# Enable registry
minikube addons enable registry

# View enabled addons
minikube addons list | grep enabled
```

### Kubernetes Dashboard

```bash
# Enable dashboard
minikube addons enable dashboard

# Access dashboard
minikube dashboard

# Dashboard URL
minikube dashboard --url
```

### Metrics Server

```bash
# Enable metrics server
minikube addons enable metrics-server

# Wait for metrics to be available (takes ~1 minute)
kubectl top nodes
kubectl top pods -n ecommerce
```

## Using Minikube Docker Daemon

To avoid pushing images to a registry, use Minikube's Docker daemon:

```bash
# Configure shell to use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify (should show Minikube's Docker)
docker info | grep "Operating System"

# Build images (they'll be available in Minikube)
docker build -t ecommerce-microservices-k8s-offers:latest ./offers-microservice-spring-boot

# List images in Minikube
minikube ssh
docker images

# Exit Minikube SSH
exit

# To revert to host Docker daemon
eval $(minikube docker-env -u)
```

### Important Notes

- Images built in Minikube's Docker are only available in Minikube
- Set `imagePullPolicy: IfNotPresent` or `Never` in pod specs
- Re-run `eval $(minikube docker-env)` in each new terminal

## Persistent Volumes

### Storage Classes

```bash
# List storage classes
kubectl get storageclass

# Describe default storage class
kubectl describe storageclass standard
```

### Persistent Volume Claim

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: ecommerce
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
# Create PVC
kubectl apply -f pvc.yaml

# View PVCs
kubectl get pvc -n ecommerce

# Use in deployment
# spec.volumes:
# - name: data-volume
#   persistentVolumeClaim:
#     claimName: app-data
# spec.containers.volumeMounts:
# - name: data-volume
#   mountPath: /app/data
```

## Networking

### Service Discovery

Services can be accessed using DNS names:

```
<service-name>.<namespace>.svc.cluster.local
```

Examples:
- `offers.ecommerce.svc.cluster.local`
- `zuul.ecommerce.svc.cluster.local`

Within the same namespace, use short names:
- `offers`
- `zuul`

### Port Forwarding

Access services locally:

```bash
# Forward pod port
kubectl port-forward pod/offers-pod 1001:1001 -n ecommerce

# Forward service port
kubectl port-forward service/offers-service 1001:1001 -n ecommerce

# Access in browser
curl http://localhost:1001/api/offers
```

### Accessing Services

```bash
# Using minikube service
minikube service ui -n ecommerce

# Get service URL
minikube service ui -n ecommerce --url

# List all service URLs
minikube service list
```

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ecommerce

# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce

# Check logs
kubectl logs <pod-name> -n ecommerce

# Previous container logs (if restarted)
kubectl logs <pod-name> -n ecommerce --previous
```

#### 2. ImagePullBackOff Error

```bash
# Verify image exists
minikube ssh
docker images | grep offers

# Check image pull policy
kubectl describe pod <pod-name> -n ecommerce | grep -A 5 "Image"

# Solution: Set imagePullPolicy: IfNotPresent
```

#### 3. CrashLoopBackOff

```bash
# View logs
kubectl logs <pod-name> -n ecommerce

# Check container configuration
kubectl describe pod <pod-name> -n ecommerce

# Debug with shell
kubectl exec -it <pod-name> -n ecommerce -- /bin/sh
```

#### 4. Service Not Accessible

```bash
# Verify service exists
kubectl get services -n ecommerce

# Check endpoints
kubectl get endpoints <service-name> -n ecommerce

# Verify pod labels match service selector
kubectl describe service <service-name> -n ecommerce
kubectl get pods -n ecommerce --show-labels
```

### Useful Debugging Commands

```bash
# Get all events
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Watch resources
kubectl get pods -n ecommerce --watch

# Resource usage
kubectl top pods -n ecommerce
kubectl top nodes

# Exec into pod
kubectl exec -it <pod-name> -n ecommerce -- /bin/bash

# Copy files from pod
kubectl cp <pod-name>:/app/logs/app.log ./app.log -n ecommerce

# DNS debugging
kubectl run -it --rm debug --image=busybox --restart=Never -n ecommerce -- sh
nslookup offers
```

## Cleanup

### Remove Resources

```bash
# Delete specific resources
kubectl delete deployment <name> -n ecommerce
kubectl delete service <name> -n ecommerce
kubectl delete pod <name> -n ecommerce

# Delete all resources in namespace
kubectl delete all --all -n ecommerce

# Delete namespace
kubectl delete namespace ecommerce

# Delete everything (use with caution!)
kubectl delete all --all --all-namespaces
```

### Stop Minikube

```bash
# Stop cluster (preserves state)
minikube stop

# Delete cluster
minikube delete

# Delete all clusters
minikube delete --all
```

## Best Practices

1. **Always use namespaces** for resource isolation
2. **Set resource limits** to prevent resource exhaustion
3. **Use labels** for organization and selection
4. **Implement health checks** (liveness and readiness probes)
5. **Use ConfigMaps and Secrets** for configuration
6. **Version your manifests** in source control
7. **Test locally** with Minikube before production deployment

## Next Steps

Proceed to [06-Helm-Introduction.md](./06-Helm-Introduction.md) to learn about Helm and how it simplifies Kubernetes deployments.
