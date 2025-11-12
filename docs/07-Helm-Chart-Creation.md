# Helm Chart Creation

This guide walks through creating a Helm chart for the e-commerce microservices application.

## Project Helm Chart Structure

Our current Helm chart structure:

```
helm-charts/
└── ecommerce-app/
    ├── Chart.yaml              # Chart metadata
    ├── values.yaml             # Default configuration
    ├── charts/                 # Dependencies (empty for now)
    └── templates/
        ├── _helpers.tpl        # Template helpers
        ├── deployment.yaml     # Deployment templates
        └── service.yaml        # Service templates
```

## Chart.yaml Analysis

Our `Chart.yaml` defines the chart metadata:

```yaml
apiVersion: v2
name: ecommerce-app
description: E-commerce microservices application

type: application

version: 0.1.0      # Chart version
appVersion: "1.0.0" # Application version
```

### Understanding Versions

- **version**: Chart version (incremented when chart changes)
- **appVersion**: Application version (the software being deployed)

## Values.yaml Structure

The `values.yaml` file contains configuration for all 6 microservices:

```yaml
global:
  imagePullPolicy: IfNotPresent

microservices:
  offers:
    enabled: true
    name: offers
    image:
      repository: ecommerce-microservices-k8s-offers
      tag: latest
    replicaCount: 1
    service:
      type: ClusterIP
      port: 1001
      targetPort: 1001
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
  
  # Similar structure for: shoes, wishlist, cart, zuul, ui
```

### Key Configuration Sections

1. **Global Settings**: Applied to all services
2. **Microservices**: Individual service configurations
3. **Image Settings**: Container image details
4. **Service Settings**: Kubernetes service configuration
5. **Resources**: CPU and memory limits

## Template Files

### 1. deployment.yaml

The deployment template creates Kubernetes Deployments for each microservice:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $service.name }}
  labels:
    app: {{ $service.name }}
spec:
  replicas: {{ $service.replicaCount }}
  selector:
    matchLabels:
      app: {{ $service.name }}
  template:
    metadata:
      labels:
        app: {{ $service.name }}
    spec:
      containers:
      - name: {{ $service.name }}
        image: "{{ $service.image.repository }}:{{ $service.image.tag }}"
        imagePullPolicy: {{ $.Values.global.imagePullPolicy }}
        ports:
        - containerPort: {{ $service.service.targetPort }}
        resources:
          {{- toYaml $service.resources | nindent 10 }}
{{- end }}
{{- end }}
```

#### Template Breakdown

**Range Loop**:
```yaml
{{- range $name, $service := .Values.microservices }}
```
Iterates over each microservice defined in values.yaml

**Conditional**:
```yaml
{{- if $service.enabled }}
```
Only creates deployment if service is enabled

**Variable Access**:
```yaml
{{ $service.name }}              # Service-specific variable
{{ $.Values.global.imagePullPolicy }}  # Global value (note the $)
```

**YAML Injection**:
```yaml
{{- toYaml $service.resources | nindent 10 }}
```
Converts resources object to YAML with proper indentation

### 2. service.yaml

The service template creates Kubernetes Services:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $service.name }}
  labels:
    app: {{ $service.name }}
    chart: {{ $.Chart.Name }}-{{ $.Chart.Version }}
    release: {{ $.Release.Name }}
spec:
  type: {{ $service.service.type }}
  ports:
    - port: {{ $service.service.port }}
      targetPort: {{ $service.service.targetPort }}
      protocol: TCP
      name: http
      {{- if and (eq $service.service.type "NodePort") ($service.service.nodePort) }}
      nodePort: {{ $service.service.nodePort }}
      {{- end }}
  selector:
    app: {{ $service.name }}
{{- end }}
{{- end }}
```

#### NodePort Configuration

For the UI service, we expose it via NodePort:

```yaml
{{- if and (eq $service.service.type "NodePort") ($service.service.nodePort) }}
nodePort: {{ $service.service.nodePort }}
{{- end }}
```

This creates a fixed port (30080) for accessing the UI externally.

### 3. _helpers.tpl

Template helpers provide reusable template snippets:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "ecommerce-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ecommerce-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ecommerce-app.labels" -}}
helm.sh/chart: {{ include "ecommerce-app.chart" . }}
{{ include "ecommerce-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ecommerce-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecommerce-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ecommerce-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

## Creating the Chart from Scratch

If you were starting fresh, here's how to create the chart:

### Step 1: Create Chart Structure

```bash
# Navigate to project root
cd /home/majidi/Desktop/ecommerce-microservices-k8s

# Create helm-charts directory
mkdir -p helm-charts
cd helm-charts

# Generate new chart
helm create ecommerce-app

# This creates the structure
tree ecommerce-app/
```

### Step 2: Modify Chart.yaml

```bash
# Edit Chart.yaml
cat > ecommerce-app/Chart.yaml <<EOF
apiVersion: v2
name: ecommerce-app
description: E-commerce microservices application
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF
```

### Step 3: Create values.yaml

```bash
# Remove default values.yaml
rm ecommerce-app/values.yaml

# Create new values.yaml with our configuration
cat > ecommerce-app/values.yaml <<'EOF'
global:
  imagePullPolicy: IfNotPresent

microservices:
  offers:
    enabled: true
    name: offers
    image:
      repository: ecommerce-microservices-k8s-offers
      tag: latest
    replicaCount: 1
    service:
      type: ClusterIP
      port: 1001
      targetPort: 1001
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
  # Add other services...
EOF
```

### Step 4: Create Templates

```bash
# Remove default templates
rm ecommerce-app/templates/*.yaml

# Create deployment.yaml
cat > ecommerce-app/templates/deployment.yaml <<'EOF'
{{- range $name, $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: apps/v1
kind: Deployment
# ... (template content)
{{- end }}
{{- end }}
EOF

# Create service.yaml
cat > ecommerce-app/templates/service.yaml <<'EOF'
{{- range $name, $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: v1
kind: Service
# ... (template content)
{{- end }}
{{- end }}
EOF
```

## Customizing the Chart

### Adding Health Checks

Add liveness and readiness probes to deployment.yaml:

```yaml
containers:
- name: {{ $service.name }}
  image: "{{ $service.image.repository }}:{{ $service.image.tag }}"
  ports:
  - containerPort: {{ $service.service.targetPort }}
  {{- if $service.livenessProbe }}
  livenessProbe:
    {{- toYaml $service.livenessProbe | nindent 12 }}
  {{- end }}
  {{- if $service.readinessProbe }}
  readinessProbe:
    {{- toYaml $service.readinessProbe | nindent 12 }}
  {{- end }}
```

In values.yaml:

```yaml
microservices:
  offers:
    # ... existing config
    livenessProbe:
      httpGet:
        path: /actuator/health
        port: 1001
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /actuator/health
        port: 1001
      initialDelaySeconds: 20
      periodSeconds: 5
```

### Adding ConfigMaps

Create configmap.yaml template:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if and $service.enabled $service.config }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $service.name }}-config
  labels:
    app: {{ $service.name }}
data:
  {{- range $key, $value := $service.config }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}
```

### Adding Secrets

Create secret.yaml template:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if and $service.enabled $service.secrets }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $service.name }}-secret
  labels:
    app: {{ $service.name }}
type: Opaque
data:
  {{- range $key, $value := $service.secrets }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
{{- end }}
{{- end }}
```

### Adding Ingress

Create ingress.yaml template:

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
  labels:
    app: ecommerce
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ .serviceName }}
                port:
                  number: {{ .servicePort }}
        {{- end }}
  {{- end }}
{{- end }}
```

## Validating the Chart

### Lint the Chart

```bash
# Check for errors and warnings
helm lint ./ecommerce-app

# Expected output
==> Linting ./ecommerce-app
[INFO] Chart.yaml: icon is recommended
1 chart(s) linted, 0 chart(s) failed
```

### Dry Run Installation

```bash
# Test without actually installing
helm install ecommerce ./ecommerce-app --dry-run --debug

# This shows what would be created
```

### Template Rendering

```bash
# Generate Kubernetes manifests
helm template ecommerce ./ecommerce-app > manifests.yaml

# Review the generated YAML
cat manifests.yaml
```

## Chart Versioning

### Semantic Versioning

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Incompatible API changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

```yaml
# Chart.yaml
version: 0.1.0  # Initial release
version: 0.2.0  # Added new feature
version: 0.2.1  # Bug fix
version: 1.0.0  # Stable release
```

### Updating Chart Version

```bash
# Edit Chart.yaml
sed -i 's/version: 0.1.0/version: 0.2.0/' ecommerce-app/Chart.yaml

# Package with new version
helm package ./ecommerce-app
```

## Creating Environment-Specific Values

### Development Environment

**values-dev.yaml:**
```yaml
global:
  imagePullPolicy: Always

microservices:
  offers:
    replicaCount: 1
    image:
      tag: dev
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
  
  # Override for other services...
```

### Staging Environment

**values-staging.yaml:**
```yaml
microservices:
  offers:
    replicaCount: 2
    image:
      tag: staging
  
  # Override for other services...
```

### Production Environment

**values-prod.yaml:**
```yaml
microservices:
  offers:
    replicaCount: 3
    image:
      tag: stable
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
  
  # Enable autoscaling
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

## Advanced Chart Features

### Adding HorizontalPodAutoscaler

Create hpa.yaml template:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if and $service.enabled $service.autoscaling $service.autoscaling.enabled }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $service.name }}-hpa
  labels:
    app: {{ $service.name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $service.name }}
  minReplicas: {{ $service.autoscaling.minReplicas }}
  maxReplicas: {{ $service.autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ $service.autoscaling.targetCPUUtilizationPercentage }}
{{- end }}
{{- end }}
```

### Adding PodDisruptionBudget

Create pdb.yaml template:

```yaml
{{- range $name, $service := .Values.microservices }}
{{- if and $service.enabled $service.podDisruptionBudget }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ $service.name }}-pdb
  labels:
    app: {{ $service.name }}
spec:
  minAvailable: {{ $service.podDisruptionBudget.minAvailable | default 1 }}
  selector:
    matchLabels:
      app: {{ $service.name }}
{{- end }}
{{- end }}
```

## Documentation

### NOTES.txt

Create a NOTES.txt file to display after installation:

```
Thank you for installing {{ .Chart.Name }}.

Your release is named {{ .Release.Name }}.

To learn more about the release, try:

  $ helm status {{ .Release.Name }}
  $ helm get all {{ .Release.Name }}

To access the application:

{{- if .Values.microservices.ui.service.nodePort }}
  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ .Values.microservices.ui.name }})
  export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
{{- else }}
  kubectl port-forward --namespace {{ .Release.Namespace }} svc/{{ .Values.microservices.ui.name }} 8080:8080
  echo http://127.0.0.1:8080
{{- end }}

Microservices deployed:
{{- range $name, $service := .Values.microservices }}
{{- if $service.enabled }}
  - {{ $service.name }}: {{ $service.image.repository }}:{{ $service.image.tag }}
{{- end }}
{{- end }}
```

### README.md for Chart

Create a comprehensive README for the chart:

```markdown
# E-commerce Application Helm Chart

## Introduction

This chart deploys an e-commerce microservices application.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+

## Installing the Chart

\`\`\`bash
helm install ecommerce ./ecommerce-app
\`\`\`

## Configuration

See `values.yaml` for configuration options.

## Uninstalling

\`\`\`bash
helm uninstall ecommerce
\`\`\`
```

## Next Steps

Proceed to [08-Deployment-Guide.md](./08-Deployment-Guide.md) for step-by-step deployment instructions.
