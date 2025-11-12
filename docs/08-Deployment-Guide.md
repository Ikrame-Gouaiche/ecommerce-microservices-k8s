# Deployment Guide

This comprehensive guide walks through deploying the e-commerce application using Helm on Kubernetes.

## Pre-Deployment Checklist

Before deploying, ensure:

- ✅ Docker is installed and running
- ✅ Minikube cluster is started
- ✅ Helm is installed
- ✅ kubectl is configured
- ✅ All source code is available

## Step-by-Step Deployment

### Step 1: Start Minikube Cluster

```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --cpus=4 --memory=8192

# Verify cluster is running
minikube status

# Expected output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured
```

### Step 2: Configure Docker Environment

To use Minikube's Docker daemon (avoids pushing to registry):

```bash
# Point Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)

# Verify you're using Minikube's Docker
docker info | grep "Operating System"
# Should show something like "Boot2Docker"
```

**Important**: Run this command in every new terminal session you use for building images.

### Step 3: Build Docker Images

Navigate to the project root and build all images:

```bash
# Navigate to project directory
cd /home/majidi/Desktop/ecommerce-microservices-k8s

# Build Offers Microservice
echo "Building Offers Microservice..."
docker build -t ecommerce-microservices-k8s-offers:latest \
  ./offers-microservice-spring-boot

# Build Shoes Microservice  
echo "Building Shoes Microservice..."
docker build -t ecommerce-microservices-k8s-shoes:latest \
  ./shoes-microservice-spring-boot

# Build Cart Microservice
echo "Building Cart Microservice..."
docker build -t ecommerce-microservices-k8s-cart:latest \
  ./cart-microservice-nodejs

# Build Wishlist Microservice
echo "Building Wishlist Microservice..."
docker build -t ecommerce-microservices-k8s-wishlist:latest \
  ./wishlist-microservice-python

# Build Zuul API Gateway
echo "Building Zuul API Gateway..."
docker build -t ecommerce-microservices-k8s-zuul:latest \
  ./zuul-api-gateway

# Build UI Web App
echo "Building UI Web App..."
docker build -t ecommerce-microservices-k8s-ui:latest \
  ./ui-web-app-reactjs
```

### Alternative: Build Script

Create and use a build script for easier execution:

```bash
# Create build script
cat > build-all-images.sh <<'EOF'
#!/bin/bash

echo "================================"
echo "Building All Docker Images"
echo "================================"

# Ensure using Minikube's Docker daemon
eval $(minikube docker-env)

# Array of services
declare -A services=(
  ["offers"]="offers-microservice-spring-boot"
  ["shoes"]="shoes-microservice-spring-boot"
  ["cart"]="cart-microservice-nodejs"
  ["wishlist"]="wishlist-microservice-python"
  ["zuul"]="zuul-api-gateway"
  ["ui"]="ui-web-app-reactjs"
)

# Build each service
for service in "${!services[@]}"; do
  echo ""
  echo "Building $service microservice..."
  docker build -t ecommerce-microservices-k8s-$service:latest ./${services[$service]}
  if [ $? -eq 0 ]; then
    echo "✅ $service built successfully"
  else
    echo "❌ $service build failed"
    exit 1
  fi
done

echo ""
echo "================================"
echo "All images built successfully!"
echo "================================"
docker images | grep ecommerce-microservices-k8s
EOF

# Make executable
chmod +x build-all-images.sh

# Run the script
./build-all-images.sh
```

### Step 4: Verify Images

```bash
# List built images
docker images | grep ecommerce-microservices-k8s

# Expected output:
# ecommerce-microservices-k8s-offers      latest    ...    ...    318MB
# ecommerce-microservices-k8s-shoes       latest    ...    ...    318MB
# ecommerce-microservices-k8s-cart        latest    ...    ...    914MB
# ecommerce-microservices-k8s-wishlist    latest    ...    ...    1.13GB
# ecommerce-microservices-k8s-zuul        latest    ...    ...    339MB
# ecommerce-microservices-k8s-ui          latest    ...    ...    1.07GB
```

### Step 5: Validate Helm Chart

Before installation, validate the Helm chart:

```bash
# Lint the chart
helm lint ./helm-charts/ecommerce-app

# Expected output:
# ==> Linting ./helm-charts/ecommerce-app
# [INFO] Chart.yaml: icon is recommended
# 1 chart(s) linted, 0 chart(s) failed

# Dry run to see what will be created
helm install ecommerce ./helm-charts/ecommerce-app --dry-run --debug

# Generate templates to review
helm template ecommerce ./helm-charts/ecommerce-app > generated-manifests.yaml
cat generated-manifests.yaml
```

### Step 6: Install the Helm Chart

```bash
# Install the chart
helm install ecommerce ./helm-charts/ecommerce-app

# Expected output:
# NAME: ecommerce
# LAST DEPLOYED: [timestamp]
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
```

### Step 7: Verify Deployment

#### Check Helm Release

```bash
# List Helm releases
helm list

# Get release status
helm status ecommerce

# View release values
helm get values ecommerce

# View deployed manifests
helm get manifest ecommerce
```

#### Check Kubernetes Resources

```bash
# View all resources
kubectl get all

# Check deployments
kubectl get deployments

# Expected output:
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# cart       1/1     1            1           2m
# offers     1/1     1            1           2m
# shoes      1/1     1            1           2m
# ui         1/1     1            1           2m
# wishlist   1/1     1            1           2m
# zuul       1/1     1            1           2m

# Check pods
kubectl get pods

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# cart-xxxxxxxxx-xxxxx        1/1     Running   0          2m
# offers-xxxxxxxxx-xxxxx      1/1     Running   0          2m
# shoes-xxxxxxxxx-xxxxx       1/1     Running   0          2m
# ui-xxxxxxxxx-xxxxx          1/1     Running   0          2m
# wishlist-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# zuul-xxxxxxxxx-xxxxx        1/1     Running   0          2m

# Check services
kubectl get services

# Expected output:
# NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
# cart         ClusterIP   10.xxx.xxx.xxx   <none>        1004/TCP         2m
# offers       ClusterIP   10.xxx.xxx.xxx   <none>        1001/TCP         2m
# shoes        ClusterIP   10.xxx.xxx.xxx   <none>        1002/TCP         2m
# ui           NodePort    10.xxx.xxx.xxx   <none>        8080:30080/TCP   2m
# wishlist     ClusterIP   10.xxx.xxx.xxx   <none>        1003/TCP         2m
# zuul         ClusterIP   10.xxx.xxx.xxx   <none>        9999/TCP         2m
```

### Step 8: Wait for Pods to be Ready

```bash
# Watch pod status
kubectl get pods --watch

# Wait for all pods to be Running
kubectl wait --for=condition=ready pod --all --timeout=300s

# Check if any pods are failing
kubectl get pods | grep -v Running
```

### Step 9: Check Pod Logs

```bash
# Check logs for each service
kubectl logs -l app=offers --tail=50
kubectl logs -l app=shoes --tail=50
kubectl logs -l app=cart --tail=50
kubectl logs -l app=wishlist --tail=50
kubectl logs -l app=zuul --tail=50
kubectl logs -l app=ui --tail=50

# Follow logs in real-time
kubectl logs -f -l app=zuul
```

### Step 10: Access the Application

#### Method 1: Using Minikube Service

```bash
# Get the UI service URL
minikube service ui --url

# Expected output (example):
# http://192.168.49.2:30080

# Open in browser
minikube service ui
```

#### Method 2: Port Forwarding

```bash
# Forward the UI service port
kubectl port-forward service/ui 8080:8080

# Access in browser: http://localhost:8080
```

#### Method 3: Using NodePort

```bash
# Get Minikube IP
minikube ip

# Get NodePort
kubectl get service ui -o jsonpath='{.spec.ports[0].nodePort}'

# Access: http://<minikube-ip>:<nodeport>
# Example: http://192.168.49.2:30080
```

## Deployment with Custom Values

### Using Environment-Specific Values

```bash
# Development deployment
helm install ecommerce-dev ./helm-charts/ecommerce-app \
  -f ./helm-charts/ecommerce-app/values-dev.yaml

# Staging deployment
helm install ecommerce-staging ./helm-charts/ecommerce-app \
  -f ./helm-charts/ecommerce-app/values-staging.yaml \
  --namespace staging --create-namespace

# Production deployment
helm install ecommerce-prod ./helm-charts/ecommerce-app \
  -f ./helm-charts/ecommerce-app/values-prod.yaml \
  --namespace production --create-namespace
```

### Override Values via Command Line

```bash
# Override replica count
helm install ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=3

# Override multiple values
helm install ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=3 \
  --set microservices.shoes.replicaCount=2 \
  --set global.imagePullPolicy=Always

# Override image tags
helm install ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0 \
  --set microservices.shoes.image.tag=v2.0
```

## Namespace Deployment

### Create and Use Namespace

```bash
# Create namespace
kubectl create namespace ecommerce

# Install in specific namespace
helm install ecommerce ./helm-charts/ecommerce-app \
  --namespace ecommerce

# View resources in namespace
kubectl get all -n ecommerce

# Set default namespace for kubectl
kubectl config set-context --current --namespace=ecommerce
```

## Monitoring Deployment

### Real-Time Monitoring

```bash
# Watch all resources
watch kubectl get all

# Watch pods only
watch kubectl get pods

# Watch with more details
kubectl get pods -o wide --watch
```

### Using k9s (if installed)

```bash
# Launch k9s
k9s

# Navigate using:
# :pods      - View pods
# :svc       - View services
# :deploy    - View deployments
# <Enter>    - Describe resource
# l          - View logs
# q          - Back/Quit
```

### Kubernetes Dashboard

```bash
# Enable and access dashboard
minikube addons enable dashboard
minikube addons enable metrics-server

# Open dashboard
minikube dashboard
```

## Troubleshooting Deployment Issues

### Issue 1: ImagePullBackOff

**Symptom**: Pod status shows `ImagePullBackOff` or `ErrImagePull`

```bash
# Check pod description
kubectl describe pod <pod-name>

# Look for image pull errors
kubectl get events --sort-by='.lastTimestamp'
```

**Solution**:
```bash
# Ensure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Verify image exists
docker images | grep <image-name>

# Rebuild image if missing
docker build -t <image-name>:latest ./<service-directory>

# Ensure imagePullPolicy is set correctly
# In values.yaml: imagePullPolicy: IfNotPresent
```

### Issue 2: CrashLoopBackOff

**Symptom**: Pod keeps restarting

```bash
# Check pod logs
kubectl logs <pod-name>

# Check previous logs if pod restarted
kubectl logs <pod-name> --previous

# Describe pod for events
kubectl describe pod <pod-name>
```

**Common causes**:
- Application error on startup
- Missing configuration
- Port already in use
- Insufficient resources

### Issue 3: Pods Not Ready

**Symptom**: Pods stay in `ContainerCreating` or `Pending` state

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes

# Check if node has capacity
kubectl describe nodes
```

**Solution**:
```bash
# If resource issue, reduce resource requests
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.requests.cpu=100m \
  --set microservices.offers.resources.requests.memory=128Mi
```

### Issue 4: Service Not Accessible

**Symptom**: Cannot access service

```bash
# Check service exists
kubectl get service <service-name>

# Check endpoints (should have pod IPs)
kubectl get endpoints <service-name>

# Test service from another pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
wget -O- http://<service-name>:<port>
```

## Deployment Verification Tests

### Test Internal Services

```bash
# Create a test pod
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the test pod, test services:
curl http://offers:1001/api/offers
curl http://shoes:1002/api/shoes
curl http://cart:1004/api/cart
curl http://wishlist:1003/api/wishlist
curl http://zuul:9999/api/offers
```

### Test External Access

```bash
# Get UI URL
minikube service ui --url

# Test with curl
curl $(minikube service ui --url)

# Or in browser
xdg-open $(minikube service ui --url)  # Linux
open $(minikube service ui --url)      # macOS
```

### Check Service Health

```bash
# For Spring Boot services (with Actuator)
kubectl exec -it <offers-pod-name> -- curl http://localhost:1001/actuator/health

# Create a script to check all services
cat > check-health.sh <<'EOF'
#!/bin/bash
for service in offers shoes zuul; do
  echo "Checking $service..."
  kubectl exec -it $(kubectl get pod -l app=$service -o jsonpath='{.items[0].metadata.name}') -- \
    curl -s http://localhost:1001/actuator/health || echo "Failed"
done
EOF
chmod +x check-health.sh
./check-health.sh
```

## Performance Tuning

### Adjust Resources

```bash
# Monitor resource usage
kubectl top pods

# If pods use more resources, update limits
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.memory=1Gi
```

### Scale Deployments

```bash
# Scale specific deployment
kubectl scale deployment offers --replicas=3

# Or via Helm upgrade
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=3
```

## Cleanup

### Uninstall Release

```bash
# Uninstall Helm release
helm uninstall ecommerce

# Verify resources are removed
kubectl get all

# If namespace was created, delete it
kubectl delete namespace ecommerce
```

### Clean Docker Images

```bash
# Switch back to host Docker
eval $(minikube docker-env -u)

# Remove old images from Minikube
minikube ssh
docker system prune -a -f
exit
```

### Stop Minikube

```bash
# Stop cluster (preserves data)
minikube stop

# Delete cluster completely
minikube delete
```

## Best Practices

1. **Always validate before deploying**: Use `helm lint` and `--dry-run`
2. **Check logs regularly**: Monitor application logs for errors
3. **Use namespaces**: Separate environments (dev, staging, prod)
4. **Set resource limits**: Prevent resource exhaustion
5. **Version your images**: Use specific tags, not `latest`
6. **Test incrementally**: Deploy one service at a time initially
7. **Document custom values**: Keep track of value overrides
8. **Backup configurations**: Store values files in version control

## Next Steps

Proceed to [09-Testing-Verification.md](./09-Testing-Verification.md) to learn how to test and verify your deployment.
