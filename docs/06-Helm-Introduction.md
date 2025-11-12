# Helm Introduction

This guide introduces Helm, the package manager for Kubernetes, and explains how it simplifies application deployment.

## What is Helm?

Helm is a package manager for Kubernetes that helps you define, install, and upgrade complex Kubernetes applications. Think of it as "apt/yum/homebrew for Kubernetes."

### Why Use Helm?

**Without Helm:**
- Manage multiple YAML files manually
- Duplicate configuration across environments
- Difficult to version and share applications
- Complex updates and rollbacks
- Hard to manage dependencies

**With Helm:**
- ✅ Package applications as charts
- ✅ Template-based configuration
- ✅ Easy versioning and rollback
- ✅ Dependency management
- ✅ Share and reuse configurations

## Helm Architecture

### Key Components

```
┌─────────────────────────────────────────┐
│         Helm Client (CLI)                │
│  - Manages charts                        │
│  - Interacts with Kubernetes API         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Kubernetes Cluster               │
│  - Stores release information            │
│  - Runs deployed applications            │
└─────────────────────────────────────────┘
```

### Helm Components

| Component | Description |
|-----------|-------------|
| **Chart** | Helm package containing Kubernetes resources |
| **Release** | Instance of a chart running in cluster |
| **Repository** | Place to store and share charts |
| **Values** | Configuration parameters for charts |

## Helm Concepts

### 1. Charts

A chart is a collection of files that describe Kubernetes resources.

**Chart Structure:**
```
mychart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── charts/             # Dependency charts
├── templates/          # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── _helpers.tpl    # Template helpers
│   └── NOTES.txt       # Installation notes
└── .helmignore         # Files to ignore
```

### 2. Releases

A release is a running instance of a chart with specific configuration.

```bash
# One chart can have multiple releases
helm install myapp-dev ./mychart
helm install myapp-staging ./mychart
helm install myapp-prod ./mychart
```

### 3. Repositories

Repositories store and distribute charts.

```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Search charts
helm search repo mysql

# Update repositories
helm repo update
```

### 4. Values

Values provide configuration for charts.

```yaml
# values.yaml
replicaCount: 2
image:
  repository: myapp
  tag: latest
service:
  port: 80
```

## Helm CLI Commands

### Basic Commands

```bash
# Get Helm version
helm version

# Create a new chart
helm create mychart

# Validate chart
helm lint mychart

# Package chart
helm package mychart

# Install chart
helm install myrelease ./mychart

# List releases
helm list

# Upgrade release
helm upgrade myrelease ./mychart

# Rollback release
helm rollback myrelease 1

# Uninstall release
helm uninstall myrelease

# Get release history
helm history myrelease
```

### Repository Commands

```bash
# Add repository
helm repo add stable https://charts.helm.sh/stable

# List repositories
helm repo list

# Update repositories
helm repo update

# Search charts in all repos
helm search repo nginx

# Search charts in specific repo
helm search repo bitnami/mysql

# Remove repository
helm repo remove stable
```

### Chart Commands

```bash
# Show chart information
helm show chart ./mychart

# Show chart values
helm show values ./mychart

# Show all chart information
helm show all ./mychart

# Download chart
helm pull bitnami/mysql

# Download and untar
helm pull bitnami/mysql --untar
```

### Release Commands

```bash
# Install chart
helm install myrelease ./mychart

# Install with custom values
helm install myrelease ./mychart -f custom-values.yaml

# Install and set value via CLI
helm install myrelease ./mychart --set replicaCount=3

# Install in specific namespace
helm install myrelease ./mychart -n production

# Dry run (test without installing)
helm install myrelease ./mychart --dry-run --debug

# List all releases
helm list

# List releases in all namespaces
helm list --all-namespaces

# Get release values
helm get values myrelease

# Get release manifest
helm get manifest myrelease

# Get release notes
helm get notes myrelease
```

### Upgrade and Rollback

```bash
# Upgrade release
helm upgrade myrelease ./mychart

# Upgrade with new values
helm upgrade myrelease ./mychart -f new-values.yaml

# Upgrade or install if doesn't exist
helm upgrade --install myrelease ./mychart

# View release history
helm history myrelease

# Rollback to previous version
helm rollback myrelease

# Rollback to specific revision
helm rollback myrelease 2

# Uninstall release
helm uninstall myrelease

# Uninstall but keep history
helm uninstall myrelease --keep-history
```

## Helm Templates

### Template Syntax

Helm uses Go templates with additional functions.

#### Basic Templating

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.port }}
```

### Built-in Objects

| Object | Description |
|--------|-------------|
| `.Release.Name` | Name of the release |
| `.Release.Namespace` | Namespace for the release |
| `.Release.Service` | Service that is rendering (always Helm) |
| `.Chart` | Contents of Chart.yaml |
| `.Values` | Values passed into the template |
| `.Files` | Access files in the chart |
| `.Capabilities` | Kubernetes version and capabilities |

### Template Functions

```yaml
# String functions
{{ .Values.name | upper }}              # MYAPP
{{ .Values.name | lower }}              # myapp
{{ .Values.name | quote }}              # "myapp"
{{ .Values.name | default "app" }}      # Default value

# Number functions
{{ .Values.port | int }}                # Convert to int

# Date functions
{{ now | date "2006-01-02" }}          # Current date

# Conditionals
{{ if .Values.enabled }}
enabled: true
{{ else }}
enabled: false
{{ end }}

# Loops
{{ range .Values.items }}
- name: {{ . }}
{{ end }}
```

### Template Conditionals

```yaml
# If-else
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
{{- end }}

# If-else if-else
{{- if eq .Values.service.type "NodePort" }}
type: NodePort
{{- else if eq .Values.service.type "LoadBalancer" }}
type: LoadBalancer
{{- else }}
type: ClusterIP
{{- end }}
```

### Template Loops

```yaml
# Range over list
{{- range .Values.microservices }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
spec:
  ports:
  - port: {{ .port }}
{{- end }}

# Range with key-value
{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
```

### Template Helpers

Create reusable templates in `_helpers.tpl`:

```yaml
# templates/_helpers.tpl
{{/*
Create a default fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

# Use in templates
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

## Values Files

### Default Values

**values.yaml:**
```yaml
# Application settings
replicaCount: 2

image:
  repository: myapp
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Feature flags
ingress:
  enabled: false
  
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
```

### Environment-Specific Values

**values-dev.yaml:**
```yaml
replicaCount: 1
image:
  tag: dev
resources:
  limits:
    cpu: 200m
    memory: 256Mi
```

**values-prod.yaml:**
```yaml
replicaCount: 3
image:
  tag: stable
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
ingress:
  enabled: true
autoscaling:
  enabled: true
```

### Using Multiple Values Files

```bash
# Install with environment-specific values
helm install myapp ./mychart -f values.yaml -f values-prod.yaml

# Override specific values
helm install myapp ./mychart --set replicaCount=5

# Multiple set values
helm install myapp ./mychart \
  --set replicaCount=5 \
  --set image.tag=v2.0
```

## Chart.yaml

The Chart.yaml file contains metadata about the chart:

```yaml
apiVersion: v2
name: ecommerce-app
description: E-commerce microservices application
type: application
version: 0.1.0
appVersion: "1.0.0"

keywords:
  - ecommerce
  - microservices
  - kubernetes

maintainers:
  - name: Your Name
    email: you@example.com

dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

### Chart Types

- **application**: Complete application (default)
- **library**: Reusable chart templates

## Dependencies

### Managing Dependencies

**Chart.yaml:**
```yaml
dependencies:
  - name: mysql
    version: "9.3.x"
    repository: https://charts.bitnami.com/bitnami
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

```bash
# Download dependencies
helm dependency update ./mychart

# List dependencies
helm dependency list ./mychart

# Build dependency chart
helm dependency build ./mychart
```

## Debugging Helm Charts

### Dry Run

```bash
# Test installation without deploying
helm install myrelease ./mychart --dry-run

# With debug output
helm install myrelease ./mychart --dry-run --debug

# Generate manifest
helm template myrelease ./mychart > manifest.yaml
```

### Linting

```bash
# Check chart for issues
helm lint ./mychart

# Strict linting
helm lint ./mychart --strict
```

### Testing

```bash
# Run tests defined in templates/tests/
helm test myrelease

# View test logs
kubectl logs -n default -l 'app.kubernetes.io/instance=myrelease'
```

## Helm Hooks

Hooks allow you to intervene at specific points in a release lifecycle.

### Available Hooks

- `pre-install`: Before resources are created
- `post-install`: After all resources are created
- `pre-delete`: Before any resources are deleted
- `post-delete`: After all resources are deleted
- `pre-upgrade`: Before resources are upgraded
- `post-upgrade`: After all resources are upgraded
- `pre-rollback`: Before rollback
- `post-rollback`: After rollback

### Hook Example

```yaml
# templates/post-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-post-install"
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: post-install
        image: busybox
        command: ['sh', '-c', 'echo Post-install task complete']
      restartPolicy: Never
```

## Best Practices

### 1. Chart Organization

```
mychart/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
├── README.md
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml
    └── NOTES.txt
```

### 2. Naming Conventions

- Use lowercase, dash-separated names
- Prefix resources with release name
- Use consistent labeling

### 3. Values Design

- Provide sensible defaults
- Document all values
- Group related values
- Use nested structure

### 4. Templates

- Keep templates simple
- Use helpers for reusable content
- Add comments for complex logic
- Test with different value combinations

### 5. Documentation

- Add NOTES.txt for installation instructions
- Document values in comments
- Include README.md with examples
- Provide upgrade instructions

## Next Steps

Proceed to [07-Helm-Chart-Creation.md](./07-Helm-Chart-Creation.md) to learn how to create a Helm chart for the e-commerce application.
