# Helm Chart Repository with ChartMuseum

This guide covers setting up ChartMuseum to host and version Helm charts, enabling chart distribution and management.

## What is ChartMuseum?

ChartMuseum is an open-source Helm Chart Repository server with support for cloud storage backends, multi-tenancy, and chart manipulation.

### Features

- 📦 Host Helm charts
- 🔄 Version management
- 🔐 Authentication support
- ☁️ Multiple storage backends
- 🚀 Easy deployment
- 📊 Chart metrics

## Installation Methods

### Method 1: Run ChartMuseum Locally with Docker

```bash
# Run ChartMuseum in Docker
docker run -d \
  -p 8080:8080 \
  -e DEBUG=1 \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  -v $(pwd)/charts:/charts \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest

# Verify it's running
curl http://localhost:8080/health

# View available charts
curl http://localhost:8080/api/charts
```

### Method 2: Deploy ChartMuseum on Kubernetes

```bash
# Add ChartMuseum Helm repo
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm repo update

# Install ChartMuseum
helm install chartmuseum chartmuseum/chartmuseum \
  --set env.open.DISABLE_API=false \
  --set env.open.ALLOW_OVERWRITE=true \
  --set persistence.enabled=true \
  --set persistence.size=10Gi

# Verify installation
kubectl get pods -l app=chartmuseum
kubectl get svc chartmuseum

# Port forward to access
kubectl port-forward service/chartmuseum 8080:8080 &
```

### Method 3: Deploy ChartMuseum on Minikube

```bash
# Create deployment and service manifests
cat > chartmuseum-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chartmuseum
  labels:
    app: chartmuseum
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chartmuseum
  template:
    metadata:
      labels:
        app: chartmuseum
    spec:
      containers:
      - name: chartmuseum
        image: ghcr.io/helm/chartmuseum:latest
        imagePullPolicy: IfNotPresent
        env:
        - name: DEBUG
          value: "1"
        - name: STORAGE
          value: "local"
        - name: STORAGE_LOCAL_ROOTDIR
          value: "/charts"
        - name: DISABLE_API
          value: "false"
        - name: ALLOW_OVERWRITE
          value: "true"
        ports:
        - containerPort: 8080
          name: http
        volumeMounts:
        - name: charts-data
          mountPath: /charts
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: charts-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: chartmuseum
  labels:
    app: chartmuseum
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30800
    protocol: TCP
    name: http
  selector:
    app: chartmuseum
EOF

# Deploy
kubectl apply -f chartmuseum-deployment.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=chartmuseum --timeout=120s

# Get service URL
minikube service chartmuseum --url

# Test
CHARTMUSEUM_URL=$(minikube service chartmuseum --url)
curl $CHARTMUSEUM_URL/health
```

## Package Helm Charts

### Package the E-commerce Chart

```bash
# Navigate to helm-charts directory
cd helm-charts

# Package the chart
helm package ecommerce-app

# Output: ecommerce-app-0.1.0.tgz

# Verify package
tar -tzf ecommerce-app-0.1.0.tgz

# Package with specific version
helm package ecommerce-app --version 0.2.0

# Package and sign
helm package ecommerce-app --sign --key 'Your Name' --keyring ~/.gnupg/secring.gpg
```

### Package Multiple Versions

```bash
# Update chart version
sed -i 's/version: 0.1.0/version: 0.2.0/' ecommerce-app/Chart.yaml
helm package ecommerce-app

sed -i 's/version: 0.2.0/version: 0.3.0/' ecommerce-app/Chart.yaml
helm package ecommerce-app

# List packages
ls -lh *.tgz
```

## Upload Charts to ChartMuseum

### Using curl

```bash
# Set ChartMuseum URL
CHARTMUSEUM_URL="http://localhost:8080"
# Or if using Minikube:
# CHARTMUSEUM_URL=$(minikube service chartmuseum --url)

# Upload chart
curl --data-binary "@ecommerce-app-0.1.0.tgz" $CHARTMUSEUM_URL/api/charts

# Expected response:
# {"saved":true}

# Upload multiple versions
for chart in ecommerce-app-*.tgz; do
  echo "Uploading $chart..."
  curl --data-binary "@$chart" $CHARTMUSEUM_URL/api/charts
done

# Verify upload
curl $CHARTMUSEUM_URL/api/charts
```

### Using Helm ChartMuseum Plugin

```bash
# Install helm push plugin
helm plugin install https://github.com/chartmuseum/helm-push

# Or update if already installed
helm plugin update push

# Add ChartMuseum as Helm repo
helm repo add my-chartmuseum $CHARTMUSEUM_URL

# Push chart
helm cm-push ecommerce-app my-chartmuseum

# Or push packaged chart
helm cm-push ecommerce-app-0.1.0.tgz my-chartmuseum

# With version override
helm cm-push ecommerce-app my-chartmuseum --version 0.4.0
```

## Using Charts from Repository

### Add Repository

```bash
# Add ChartMuseum repo
helm repo add my-charts $CHARTMUSEUM_URL

# Update repositories
helm repo update

# List repositories
helm repo list
```

### Search Charts

```bash
# Search for charts
helm search repo ecommerce

# Expected output:
# NAME                          CHART VERSION  APP VERSION  DESCRIPTION
# my-charts/ecommerce-app       0.1.0          1.0.0        E-commerce microservices application

# Search all versions
helm search repo ecommerce --versions

# Show chart info
helm show chart my-charts/ecommerce-app
helm show values my-charts/ecommerce-app
helm show all my-charts/ecommerce-app
```

### Install from Repository

```bash
# Install latest version
helm install ecommerce my-charts/ecommerce-app

# Install specific version
helm install ecommerce my-charts/ecommerce-app --version 0.1.0

# Install with custom values
helm install ecommerce my-charts/ecommerce-app \
  -f my-custom-values.yaml

# Upgrade from repository
helm upgrade ecommerce my-charts/ecommerce-app --version 0.2.0
```

## Chart Versioning Strategy

### Semantic Versioning

```yaml
# Chart.yaml
version: MAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Version Management Workflow

```bash
# 1. Make changes to chart
vim ecommerce-app/templates/deployment.yaml

# 2. Update version in Chart.yaml
sed -i 's/version: 0.1.0/version: 0.1.1/' ecommerce-app/Chart.yaml

# 3. Package new version
helm package ecommerce-app

# 4. Upload to repository
curl --data-binary "@ecommerce-app-0.1.1.tgz" $CHARTMUSEUM_URL/api/charts

# 5. Update repo index
helm repo update

# 6. Upgrade deployment
helm upgrade ecommerce my-charts/ecommerce-app --version 0.1.1
```

## ChartMuseum API

### List Charts

```bash
# List all charts
curl $CHARTMUSEUM_URL/api/charts

# List specific chart versions
curl $CHARTMUSEUM_URL/api/charts/ecommerce-app
```

### Get Chart Details

```bash
# Get chart metadata
curl $CHARTMUSEUM_URL/api/charts/ecommerce-app/0.1.0

# Download chart
curl -O $CHARTMUSEUM_URL/charts/ecommerce-app-0.1.0.tgz
```

### Delete Charts

```bash
# Delete specific version
curl -X DELETE $CHARTMUSEUM_URL/api/charts/ecommerce-app/0.1.0

# Verify deletion
curl $CHARTMUSEUM_URL/api/charts/ecommerce-app
```

### Health Check

```bash
# Check health
curl $CHARTMUSEUM_URL/health

# Check storage
curl $CHARTMUSEUM_URL/api/storage
```

## Automated Chart Publishing

### CI/CD Pipeline Script

```bash
cat > publish-chart.sh <<'EOF'
#!/bin/bash

set -e

CHART_DIR="helm-charts/ecommerce-app"
CHARTMUSEUM_URL=${CHARTMUSEUM_URL:-"http://localhost:8080"}

echo "========================================="
echo "Automated Chart Publishing"
echo "========================================="

# 1. Get current version
CURRENT_VERSION=$(grep '^version:' $CHART_DIR/Chart.yaml | awk '{print $2}')
echo "Current version: $CURRENT_VERSION"

# 2. Lint chart
echo "Linting chart..."
helm lint $CHART_DIR

# 3. Package chart
echo "Packaging chart..."
helm package $CHART_DIR

PACKAGE_FILE="ecommerce-app-${CURRENT_VERSION}.tgz"

# 4. Upload to ChartMuseum
echo "Uploading to ChartMuseum..."
curl --fail --data-binary "@$PACKAGE_FILE" $CHARTMUSEUM_URL/api/charts

# 5. Verify upload
echo "Verifying upload..."
sleep 2
curl $CHARTMUSEUM_URL/api/charts/ecommerce-app/$CURRENT_VERSION

# 6. Update Helm repos
echo "Updating Helm repositories..."
helm repo update

echo "========================================="
echo "Chart published successfully!"
echo "Version: $CURRENT_VERSION"
echo "========================================="
EOF

chmod +x publish-chart.sh
```

### Version Bumping Script

```bash
cat > bump-version.sh <<'EOF'
#!/bin/bash

CHART_YAML="helm-charts/ecommerce-app/Chart.yaml"
BUMP_TYPE=${1:-patch}  # major, minor, or patch

# Get current version
CURRENT_VERSION=$(grep '^version:' $CHART_YAML | awk '{print $2}')
echo "Current version: $CURRENT_VERSION"

# Parse version
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump version
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Usage: $0 [major|minor|patch]"
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Update Chart.yaml
sed -i "s/^version: .*/version: $NEW_VERSION/" $CHART_YAML

echo "Version bumped to $NEW_VERSION"
EOF

chmod +x bump-version.sh

# Usage:
# ./bump-version.sh patch  # 0.1.0 -> 0.1.1
# ./bump-version.sh minor  # 0.1.1 -> 0.2.0
# ./bump-version.sh major  # 0.2.0 -> 1.0.0
```

## Chart Index

ChartMuseum automatically maintains an index.yaml file:

```bash
# View index
curl $CHARTMUSEUM_URL/index.yaml

# Download index
curl -O $CHARTMUSEUM_URL/index.yaml

# Regenerate index (if needed)
helm repo index . --url $CHARTMUSEUM_URL
```

## Security and Authentication

### Basic Authentication

```bash
# Run ChartMuseum with auth
docker run -d \
  -p 8080:8080 \
  -e BASIC_AUTH_USER=admin \
  -e BASIC_AUTH_PASS=password123 \
  -v $(pwd)/charts:/charts \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest

# Upload with auth
curl -u admin:password123 \
  --data-binary "@ecommerce-app-0.1.0.tgz" \
  http://localhost:8080/api/charts

# Add repo with auth
helm repo add my-charts \
  http://localhost:8080 \
  --username admin \
  --password password123
```

### TLS/SSL

```bash
# Run with TLS
docker run -d \
  -p 8443:8443 \
  -e TLS_CERT=/certs/tls.crt \
  -e TLS_KEY=/certs/tls.key \
  -v $(pwd)/certs:/certs \
  -v $(pwd)/charts:/charts \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest

# Add repo with TLS
helm repo add my-charts https://localhost:8443 \
  --ca-file ca.crt
```

## Cloud Storage Backends

### AWS S3

```bash
docker run -d \
  -p 8080:8080 \
  -e STORAGE=amazon \
  -e STORAGE_AMAZON_BUCKET=my-charts-bucket \
  -e STORAGE_AMAZON_PREFIX=charts \
  -e STORAGE_AMAZON_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=<access-key> \
  -e AWS_SECRET_ACCESS_KEY=<secret-key> \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest
```

### Google Cloud Storage

```bash
docker run -d \
  -p 8080:8080 \
  -e STORAGE=google \
  -e STORAGE_GOOGLE_BUCKET=my-charts-bucket \
  -e STORAGE_GOOGLE_PREFIX=charts \
  -e GOOGLE_APPLICATION_CREDENTIALS=/credentials/gcs-key.json \
  -v /path/to/gcs-key.json:/credentials/gcs-key.json \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest
```

### Azure Blob Storage

```bash
docker run -d \
  -p 8080:8080 \
  -e STORAGE=microsoft \
  -e STORAGE_MICROSOFT_CONTAINER=charts \
  -e AZURE_STORAGE_ACCOUNT=<account> \
  -e AZURE_STORAGE_ACCESS_KEY=<key> \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest
```

## Multi-Tenancy

Enable multi-tenancy for different organizations:

```bash
# Run with multi-tenancy
docker run -d \
  -p 8080:8080 \
  -e MULTITENANT=1 \
  -v $(pwd)/charts:/charts \
  --name chartmuseum \
  ghcr.io/helm/chartmuseum:latest

# Upload to tenant
curl --data-binary "@ecommerce-app-0.1.0.tgz" \
  http://localhost:8080/tenant1/api/charts

# Add tenant repo
helm repo add tenant1 http://localhost:8080/tenant1
```

## Backup and Restore

### Backup Charts

```bash
# Backup all charts from ChartMuseum
mkdir -p chartmuseum-backup
cd chartmuseum-backup

# Download all charts
for chart in $(curl -s $CHARTMUSEUM_URL/api/charts | jq -r 'keys[]'); do
  for version in $(curl -s $CHARTMUSEUM_URL/api/charts/$chart | jq -r '.[].version'); do
    echo "Downloading $chart-$version..."
    curl -O $CHARTMUSEUM_URL/charts/$chart-$version.tgz
  done
done

# Backup index
curl -O $CHARTMUSEUM_URL/index.yaml
```

### Restore Charts

```bash
# Restore all charts to new ChartMuseum
for chart in *.tgz; do
  echo "Uploading $chart..."
  curl --data-binary "@$chart" $NEW_CHARTMUSEUM_URL/api/charts
done
```

## Monitoring ChartMuseum

### Metrics

```bash
# Get metrics (if Prometheus endpoint enabled)
curl $CHARTMUSEUM_URL/metrics
```

### Logs

```bash
# Docker logs
docker logs chartmuseum -f

# Kubernetes logs
kubectl logs -f deployment/chartmuseum
```

## Best Practices

1. **Version Control**: Always use semantic versioning
2. **Automated Testing**: Lint and test charts before publishing
3. **CI/CD Integration**: Automate chart publishing in pipeline
4. **Security**: Use authentication and TLS in production
5. **Backup**: Regularly backup chart repository
6. **Documentation**: Maintain README and NOTES.txt in charts
7. **Storage**: Use cloud storage backends for production
8. **Monitoring**: Monitor ChartMuseum health and metrics

## Complete Workflow Example

```bash
# 1. Make changes to chart
vim helm-charts/ecommerce-app/values.yaml

# 2. Bump version
./bump-version.sh minor

# 3. Test chart
helm lint helm-charts/ecommerce-app
helm install test helm-charts/ecommerce-app --dry-run --debug

# 4. Package and publish
./publish-chart.sh

# 5. Verify in repository
helm search repo ecommerce --versions

# 6. Deploy new version
helm upgrade ecommerce my-charts/ecommerce-app
```

## Next Steps

Proceed to [12-Troubleshooting.md](./12-Troubleshooting.md) for common issues and solutions.
