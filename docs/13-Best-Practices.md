# Best Practices and Recommendations

This guide provides best practices for deploying microservices applications with Helm on Kubernetes.

## Helm Chart Best Practices

### Chart Structure

```
chart-name/
├── Chart.yaml          # Clear, descriptive metadata
├── values.yaml         # Well-documented defaults
├── README.md           # Comprehensive documentation
├── .helmignore         # Exclude unnecessary files
├── templates/
│   ├── NOTES.txt       # Post-install instructions
│   ├── _helpers.tpl    # Reusable templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── tests/          # Helm tests
└── charts/             # Dependencies
```

### Chart.yaml Best Practices

```yaml
apiVersion: v2
name: ecommerce-app
description: >
  E-commerce microservices application with Spring Boot,
  Node.js, Python, and React components

# Use semantic versioning
version: 1.0.0
appVersion: "2.1.0"

keywords:
  - ecommerce
  - microservices
  - spring-boot
  - nodejs
  - react

maintainers:
  - name: Your Name
    email: your.email@example.com
    url: https://github.com/yourusername

home: https://github.com/yourusername/project
sources:
  - https://github.com/yourusername/project

# Define dependencies with version constraints
dependencies:
  - name: postgresql
    version: "~12.1.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled

# Icon for chart repository
icon: https://example.com/icon.png
```

### values.yaml Best Practices

```yaml
# Document all values with comments
global:
  # ImagePullPolicy for all containers
  imagePullPolicy: IfNotPresent
  
  # Common labels applied to all resources
  labels:
    environment: production
    team: platform

# Group related values together
microservices:
  offers:
    # Enable/disable service deployment
    enabled: true
    
    # Service name (used for DNS)
    name: offers
    
    # Container image configuration
    image:
      repository: ecommerce-offers
      tag: "1.0.0"  # Avoid 'latest' in production
      pullPolicy: IfNotPresent
    
    # Number of replicas (use odd numbers for HA)
    replicaCount: 3
    
    # Resource limits and requests
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
    
    # Health check configuration
    livenessProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 1001
      initialDelaySeconds: 60
      periodSeconds: 10
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 1001
      initialDelaySeconds: 30
      periodSeconds: 5
      failureThreshold: 3
```

### Template Best Practices

#### Use Consistent Naming

```yaml
{{/* Define consistent naming helper */}}
{{- define "ecommerce.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Use the helper throughout templates */}}
metadata:
  name: {{ include "ecommerce.fullname" . }}
```

#### Add Resource Labels

```yaml
{{- define "ecommerce.labels" -}}
app.kubernetes.io/name: {{ include "ecommerce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "ecommerce.chart" . }}
{{- end -}}

metadata:
  labels:
    {{- include "ecommerce.labels" . | nindent 4 }}
```

#### Use Conditional Rendering

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
# ...
{{- end }}
```

#### Validate Required Values

```yaml
{{- if not .Values.microservices.offers.image.repository }}
{{- fail "microservices.offers.image.repository is required" }}
{{- end }}
```

## Kubernetes Best Practices

### Resource Management

```yaml
# Always set resource requests and limits
resources:
  limits:
    cpu: 500m      # Maximum CPU
    memory: 512Mi  # Maximum memory
  requests:
    cpu: 250m      # Guaranteed CPU
    memory: 256Mi  # Guaranteed memory

# Use QoS classes appropriately:
# - Guaranteed: requests == limits (critical services)
# - Burstable: requests < limits (most services)
# - BestEffort: no requests/limits (development only)
```

### Health Checks

```yaml
# Liveness probe: Restart container if unhealthy
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 60  # Wait for startup
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

# Readiness probe: Remove from service if not ready
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

# Startup probe: For slow-starting containers
startupProbe:
  httpGet:
    path: /health/startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30  # 5 minutes max
```

### Security

```yaml
# Run as non-root user
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true

# Use secrets for sensitive data
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password

# Use network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: offers-netpol
spec:
  podSelector:
    matchLabels:
      app: offers
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: zuul
      ports:
        - port: 1001
```

### High Availability

```yaml
# Use multiple replicas
replicas: 3

# Pod anti-affinity for node distribution
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: offers
          topologyKey: kubernetes.io/hostname

# Pod disruption budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: offers-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: offers
```

## Docker Best Practices

### Dockerfile Optimization

```dockerfile
# Use specific versions, not 'latest'
FROM openjdk:11.0.16-jre-slim

# Use multi-stage builds
FROM maven:3.8-openjdk-11 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM openjdk:11.0.16-jre-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Create non-root user
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser
USER appuser

# Use EXPOSE for documentation
EXPOSE 1001

# Use ENTRYPOINT and CMD
ENTRYPOINT ["java"]
CMD ["-jar", "app.jar"]

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:1001/actuator/health || exit 1
```

### Image Tagging Strategy

```bash
# Use semantic versioning
docker build -t myapp:1.2.3 .

# Tag with git commit
docker build -t myapp:$(git rev-parse --short HEAD) .

# Tag with build number
docker build -t myapp:build-${BUILD_NUMBER} .

# Multiple tags
docker build \
  -t myapp:1.2.3 \
  -t myapp:1.2 \
  -t myapp:1 \
  -t myapp:latest \
  .
```

### .dockerignore

```
# Version control
.git
.gitignore

# IDE
.vscode
.idea
*.swp
*.swo

# Build artifacts
target/
build/
dist/
node_modules/

# Documentation
README.md
docs/

# Tests
**/*test*
**/*Test*

# Logs
*.log

# OS
.DS_Store
Thumbs.db
```

## Development Workflow

### Local Development

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192

# 2. Use Minikube's Docker
eval $(minikube docker-env)

# 3. Build images
./build-images.sh

# 4. Deploy with Helm
helm install ecommerce-dev ./helm-charts/ecommerce-app \
  -f values-dev.yaml

# 5. Access services
minikube service ui
```

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker images
        run: |
          docker build -t myregistry/offers:${GITHUB_SHA} ./offers-microservice
          
      - name: Push images
        run: |
          docker push myregistry/offers:${GITHUB_SHA}
          
      - name: Deploy with Helm
        run: |
          helm upgrade --install ecommerce ./helm-charts/ecommerce-app \
            --set microservices.offers.image.tag=${GITHUB_SHA}
```

## Configuration Management

### Environment-Specific Values

```
helm-charts/
└── ecommerce-app/
    ├── values.yaml         # Default values
    ├── values-dev.yaml     # Development overrides
    ├── values-staging.yaml # Staging overrides
    └── values-prod.yaml    # Production overrides
```

### Using ConfigMaps

```yaml
# Separate configuration from deployment
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.properties: |
    server.port=1001
    logging.level.root=INFO
  
# Mount as file
volumes:
  - name: config
    configMap:
      name: app-config
volumeMounts:
  - name: config
    mountPath: /config
    readOnly: true
```

### Using Secrets

```bash
# Create secret from literal
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='S3cr3tP@ss'

# Create from file
kubectl create secret generic tls-cert \
  --from-file=tls.crt \
  --from-file=tls.key

# Use in deployment
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

## Monitoring and Observability

### Logging

```yaml
# Structured logging configuration
env:
  - name: LOG_FORMAT
    value: json
  - name: LOG_LEVEL
    value: info

# Use stdout/stderr (collected by Kubernetes)
# Avoid writing to files in containers
```

### Metrics

```yaml
# Expose Prometheus metrics
apiVersion: v1
kind: Service
metadata:
  name: offers
  labels:
    app: offers
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "1001"
    prometheus.io/path: "/actuator/prometheus"
```

### Distributed Tracing

```yaml
# Add tracing configuration
env:
  - name: JAEGER_AGENT_HOST
    value: jaeger-agent
  - name: JAEGER_AGENT_PORT
    value: "6831"
  - name: JAEGER_SAMPLER_TYPE
    value: const
  - name: JAEGER_SAMPLER_PARAM
    value: "1"
```

## Versioning and Releases

### Git Workflow

```bash
# Feature branch
git checkout -b feature/new-feature
# Make changes
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Bump version
./bump-version.sh minor

# Tag release
git tag v1.1.0
git push origin v1.1.0

# Deploy
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.tag=v1.1.0
```

### Changelog

Maintain a CHANGELOG.md:

```markdown
# Changelog

## [1.1.0] - 2025-11-12

### Added
- New wishlist feature
- Enhanced error handling

### Changed
- Updated dependencies
- Improved performance

### Fixed
- Bug in cart calculation
```

## Testing Strategy

### Unit Tests

```bash
# Java/Spring Boot
cd offers-microservice-spring-boot
./mvnw test

# Node.js
cd cart-microservice-nodejs
npm test

# Python
cd wishlist-microservice-python
python -m pytest
```

### Integration Tests

```bash
# Deploy test environment
helm install test ./helm-charts/ecommerce-app \
  --namespace test \
  --create-namespace

# Run integration tests
./run-integration-tests.sh

# Cleanup
helm uninstall test -n test
kubectl delete namespace test
```

### Helm Tests

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "ecommerce.fullname" . }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "ecommerce.fullname" . }}:80']
  restartPolicy: Never
```

```bash
# Run Helm tests
helm test ecommerce
```

## Documentation

### README.md for Chart

```markdown
# E-commerce Application Helm Chart

## Quick Start

\`\`\`bash
helm install ecommerce ./ecommerce-app
\`\`\`

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `microservices.offers.replicaCount` | Number of replicas | `2` |

## Upgrading

\`\`\`bash
helm upgrade ecommerce ./ecommerce-app
\`\`\`

## Uninstalling

\`\`\`bash
helm uninstall ecommerce
\`\`\`
```

### NOTES.txt

```
Thank you for installing {{ .Chart.Name }}.

Your release is named {{ .Release.Name }}.

To access the application:
  export POD_NAME=$(kubectl get pods -l "app={{ .Values.microservices.ui.name }}" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward $POD_NAME 8080:8080
  echo "Visit http://127.0.0.1:8080"

For more information:
  helm status {{ .Release.Name }}
  helm get all {{ .Release.Name }}
```

## Deployment Checklist

### Pre-Deployment

- [ ] Code reviewed and tested
- [ ] Docker images built and tagged
- [ ] Helm chart linted (`helm lint`)
- [ ] Dry run successful (`--dry-run`)
- [ ] Resource limits configured
- [ ] Health checks implemented
- [ ] Secrets created
- [ ] Backup of current state

### Deployment

- [ ] Deploy to staging first
- [ ] Verify staging deployment
- [ ] Monitor logs and metrics
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Monitor rollout

### Post-Deployment

- [ ] Verify all pods running
- [ ] Check service endpoints
- [ ] Run integration tests
- [ ] Monitor metrics
- [ ] Update documentation
- [ ] Tag release in git

## Summary of Key Practices

1. **Always use version control** for charts and code
2. **Lint and test** before deploying
3. **Use semantic versioning** for charts and images
4. **Set resource limits** on all containers
5. **Implement health checks** (liveness, readiness)
6. **Run as non-root** for security
7. **Use secrets** for sensitive data
8. **Multiple replicas** for high availability
9. **Monitor everything** (logs, metrics, traces)
10. **Document thoroughly** (README, values, NOTES)
11. **Test in staging** before production
12. **Have rollback plan** ready
13. **Regular backups** of critical data
14. **Keep dependencies updated**
15. **Follow GitOps** practices

## Conclusion

This documentation set provides a comprehensive guide to deploying microservices applications with Helm on Kubernetes. Following these best practices will help ensure reliable, secure, and maintainable deployments.

For questions or issues, refer to:
- [Troubleshooting Guide](./12-Troubleshooting.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
