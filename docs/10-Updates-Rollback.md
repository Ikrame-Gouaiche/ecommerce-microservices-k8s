# Updates and Rollback

This guide covers application updates, version management, and rollback procedures using Helm.

## Understanding Helm Releases

Every time you install or upgrade a chart, Helm creates a new revision:

```bash
# View release history
helm history ecommerce

# Output example:
# REVISION  UPDATED                   STATUS      CHART               DESCRIPTION
# 1         Mon Nov 12 10:00:00 2025  deployed    ecommerce-app-0.1.0 Install complete
```

## Application Updates

### Updating Application Code

#### Step 1: Make Code Changes

For example, update the Offers service:

```bash
# Navigate to offers service
cd offers-microservice-spring-boot/src/main/java/com/microservices/offers/controllers

# Edit OffersController.java (make your changes)
```

#### Step 2: Rebuild Docker Image

```bash
# Ensure using Minikube's Docker
eval $(minikube docker-env)

# Rebuild with new tag
docker build -t ecommerce-microservices-k8s-offers:v2.0 \
  ./offers-microservice-spring-boot

# Or update latest tag
docker build -t ecommerce-microservices-k8s-offers:latest \
  ./offers-microservice-spring-boot
```

#### Step 3: Update Helm Release

**Method 1: Using --set**

```bash
# Update with new image tag
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0

# Verify update
helm history ecommerce
```

**Method 2: Update values.yaml**

```bash
# Edit values.yaml
sed -i 's/tag: latest/tag: v2.0/' helm-charts/ecommerce-app/values.yaml

# Apply changes
helm upgrade ecommerce ./helm-charts/ecommerce-app
```

**Method 3: Using values file**

```bash
# Create update values file
cat > update-values.yaml <<EOF
microservices:
  offers:
    image:
      tag: v2.0
EOF

# Apply update
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  -f update-values.yaml
```

#### Step 4: Monitor Update

```bash
# Watch rollout status
kubectl rollout status deployment/offers

# View pod updates
kubectl get pods -l app=offers --watch

# Check new pod logs
kubectl logs -l app=offers --tail=50
```

### Updating Multiple Services

```bash
# Rebuild all images with new version
./build-all-images.sh

# Update all services
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0 \
  --set microservices.shoes.image.tag=v2.0 \
  --set microservices.cart.image.tag=v2.0 \
  --set microservices.wishlist.image.tag=v2.0 \
  --set microservices.zuul.image.tag=v2.0 \
  --set microservices.ui.image.tag=v2.0
```

### Updating Configuration

#### Update Resource Limits

```bash
# Increase memory for offers service
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.memory=1Gi \
  --set microservices.offers.resources.requests.memory=512Mi
```

#### Update Replica Count

```bash
# Scale up offers service
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=3

# Scale multiple services
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=3 \
  --set microservices.shoes.replicaCount=3 \
  --set microservices.zuul.replicaCount=2
```

#### Update Service Type

```bash
# Change UI service to LoadBalancer
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.ui.service.type=LoadBalancer
```

### Updating Chart Version

When the chart itself changes:

```bash
# Update Chart.yaml version
sed -i 's/version: 0.1.0/version: 0.2.0/' helm-charts/ecommerce-app/Chart.yaml

# Upgrade to new chart version
helm upgrade ecommerce ./helm-charts/ecommerce-app

# Verify chart version
helm list
```

## Rollout Strategies

### Rolling Update (Default)

Helm/Kubernetes gradually replaces old pods with new ones:

```yaml
# In deployment spec (already configured)
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count
      maxUnavailable: 0  # Max pods unavailable during update
```

```bash
# Perform rolling update
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0

# Monitor rollout
kubectl rollout status deployment/offers

# Pause rollout (if needed)
kubectl rollout pause deployment/offers

# Resume rollout
kubectl rollout resume deployment/offers
```

### Recreate Strategy

All old pods are killed before new ones are created:

```yaml
# Add to deployment template
spec:
  strategy:
    type: Recreate
```

### Blue-Green Deployment

Deploy new version alongside old version:

```bash
# Install new version with different name
helm install ecommerce-green ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0

# Test green deployment
kubectl get pods | grep green

# Switch traffic (update service selector or ingress)
# Then remove old deployment
helm uninstall ecommerce
```

### Canary Deployment

Gradually shift traffic to new version:

```bash
# Keep current version running
helm list

# Deploy canary with fewer replicas
helm install ecommerce-canary ./helm-charts/ecommerce-app \
  --set microservices.offers.replicaCount=1 \
  --set microservices.offers.image.tag=v2.0

# Monitor canary
kubectl logs -l app=offers,version=canary

# If stable, upgrade main deployment
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0

# Remove canary
helm uninstall ecommerce-canary
```

## Rollback Procedures

### View Release History

```bash
# List all revisions
helm history ecommerce

# Output:
# REVISION  UPDATED                   STATUS      CHART               DESCRIPTION
# 1         Mon Nov 12 10:00:00 2025  superseded  ecommerce-app-0.1.0 Install complete
# 2         Mon Nov 12 11:00:00 2025  superseded  ecommerce-app-0.1.0 Upgrade complete
# 3         Mon Nov 12 12:00:00 2025  deployed    ecommerce-app-0.1.0 Upgrade complete

# View specific revision
helm get values ecommerce --revision 2
helm get manifest ecommerce --revision 2
```

### Rollback to Previous Version

```bash
# Rollback to previous revision
helm rollback ecommerce

# Verify rollback
helm history ecommerce

# Output shows new revision:
# REVISION  UPDATED                   STATUS      CHART               DESCRIPTION
# 1         Mon Nov 12 10:00:00 2025  superseded  ecommerce-app-0.1.0 Install complete
# 2         Mon Nov 12 11:00:00 2025  superseded  ecommerce-app-0.1.0 Upgrade complete
# 3         Mon Nov 12 12:00:00 2025  superseded  ecommerce-app-0.1.0 Upgrade complete
# 4         Mon Nov 12 12:30:00 2025  deployed    ecommerce-app-0.1.0 Rollback to 2
```

### Rollback to Specific Revision

```bash
# Rollback to revision 1
helm rollback ecommerce 1

# Verify
helm history ecommerce
kubectl get pods
```

### Monitoring Rollback

```bash
# Watch rollout during rollback
kubectl rollout status deployment/offers

# View pod changes
kubectl get pods --watch

# Check logs after rollback
kubectl logs -l app=offers --tail=50
```

## Simulating Erroneous Update and Rollback

### Scenario: Deploy Broken Version

#### Step 1: Create a Broken Version

```bash
# Simulate broken image (non-existent tag)
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=broken-v9.9.9
```

#### Step 2: Observe Failure

```bash
# Check pod status
kubectl get pods -l app=offers

# Output shows ImagePullBackOff:
# NAME                      READY   STATUS             RESTARTS   AGE
# offers-xxxxxxxxx-xxxxx    0/1     ImagePullBackOff   0          30s

# Describe pod to see error
kubectl describe pod -l app=offers | grep -A 10 Events

# Check deployment
kubectl get deployment offers
# Output shows:
# NAME     READY   UP-TO-DATE   AVAILABLE   AGE
# offers   1/2     1            1           5m
```

#### Step 3: Perform Rollback

```bash
# View history
helm history ecommerce

# Rollback to previous working version
helm rollback ecommerce

# Monitor rollback
kubectl rollout status deployment/offers

# Verify pods are healthy
kubectl get pods -l app=offers
```

### Scenario: Configuration Error

#### Step 1: Deploy Bad Configuration

```bash
# Set impossibly low memory limit
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.memory=10Mi
```

#### Step 2: Observe OOMKilled Errors

```bash
# Watch pods
kubectl get pods -l app=offers --watch

# Pods will show OOMKilled or CrashLoopBackOff
# Check logs
kubectl logs -l app=offers --previous
```

#### Step 3: Rollback

```bash
# Immediate rollback
helm rollback ecommerce

# Verify
kubectl get pods -l app=offers
```

## Automated Rollback

### Health Check Based Rollback

Create a script to automatically rollback on failure:

```bash
cat > auto-rollback.sh <<'EOF'
#!/bin/bash

RELEASE_NAME="ecommerce"
SERVICE_NAME="offers"
MAX_WAIT=300  # 5 minutes
INTERVAL=10

echo "Performing upgrade..."
helm upgrade $RELEASE_NAME ./helm-charts/ecommerce-app "$@"

echo "Monitoring rollout..."
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  # Check if rollout is successful
  if kubectl rollout status deployment/$SERVICE_NAME --timeout=10s > /dev/null 2>&1; then
    echo "✅ Deployment successful!"
    exit 0
  fi
  
  # Check for ImagePullBackOff or CrashLoopBackOff
  FAILED_PODS=$(kubectl get pods -l app=$SERVICE_NAME \
    --field-selector=status.phase!=Running,status.phase!=Succeeded \
    --no-headers 2>/dev/null | wc -l)
  
  if [ $FAILED_PODS -gt 0 ]; then
    echo "❌ Deployment failed! Rolling back..."
    helm rollback $RELEASE_NAME
    echo "Rollback initiated"
    kubectl rollout status deployment/$SERVICE_NAME
    exit 1
  fi
  
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "⚠️ Deployment timeout! Rolling back..."
helm rollback $RELEASE_NAME
exit 1
EOF

chmod +x auto-rollback.sh

# Use it for upgrades
./auto-rollback.sh --set microservices.offers.image.tag=v2.0
```

## Version Management Best Practices

### Semantic Versioning

Use semantic versioning for images:

```bash
# Build with semantic version
docker build -t ecommerce-microservices-k8s-offers:1.0.0 ./offers-microservice-spring-boot
docker build -t ecommerce-microservices-k8s-offers:1.1.0 ./offers-microservice-spring-boot
docker build -t ecommerce-microservices-k8s-offers:2.0.0 ./offers-microservice-spring-boot

# Deploy specific version
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=1.1.0
```

### Tagging Strategy

```bash
# Tag with git commit hash
GIT_COMMIT=$(git rev-parse --short HEAD)
docker build -t ecommerce-microservices-k8s-offers:$GIT_COMMIT \
  ./offers-microservice-spring-boot

# Tag with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker build -t ecommerce-microservices-k8s-offers:$TIMESTAMP \
  ./offers-microservice-spring-boot

# Tag with version and latest
docker build -t ecommerce-microservices-k8s-offers:1.2.0 \
  -t ecommerce-microservices-k8s-offers:latest \
  ./offers-microservice-spring-boot
```

### Release Notes

Maintain release notes in annotations:

```yaml
metadata:
  annotations:
    release-notes: |
      Version 2.0.0
      - Added new features
      - Fixed bugs
      - Updated dependencies
```

## Helm Diff Plugin

Install and use helm-diff for safer upgrades:

```bash
# Install diff plugin
helm plugin install https://github.com/databus23/helm-diff

# Preview changes before upgrade
helm diff upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0

# Perform upgrade if diff looks good
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0
```

## Testing Updates

### Test in Dry Run Mode

```bash
# Preview upgrade without applying
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0 \
  --dry-run --debug
```

### Staging Environment Testing

```bash
# Create staging namespace
kubectl create namespace staging

# Deploy to staging first
helm install ecommerce-staging ./helm-charts/ecommerce-app \
  --namespace staging \
  --set microservices.offers.image.tag=v2.0

# Test staging
kubectl get pods -n staging

# If successful, update production
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v2.0
```

## Backup and Restore

### Backup Current State

```bash
# Export current values
helm get values ecommerce > backup-values-$(date +%Y%m%d).yaml

# Export manifest
helm get manifest ecommerce > backup-manifest-$(date +%Y%m%d).yaml

# Export entire release
helm get all ecommerce > backup-release-$(date +%Y%m%d).yaml
```

### Restore from Backup

```bash
# Rollback using saved values
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  -f backup-values-20251112.yaml
```

## Cleanup Old Revisions

Helm keeps all revision history by default:

```bash
# Limit history (keep last 10 revisions)
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --history-max 10

# Or set in Helm config
export HELM_MAX_HISTORY=10
```

## Update Checklist

Before performing updates:

- ✅ Backup current state
- ✅ Test in staging environment
- ✅ Review changes with `helm diff`
- ✅ Verify Docker images exist
- ✅ Plan rollback strategy
- ✅ Monitor application during update
- ✅ Have runbook ready for issues
- ✅ Communicate update to team
- ✅ Verify health after update

## Next Steps

Proceed to [11-Chart-Repository.md](./11-Chart-Repository.md) to learn how to host and version Helm charts in a repository.
