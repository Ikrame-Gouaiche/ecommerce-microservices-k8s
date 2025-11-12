# Horizontal Pod Autoscaler (HPA) Setup Guide

## Overview

The HPA configuration has been added to your Helm chart with extensive comments explaining every aspect of autoscaling in Kubernetes.

## Files Created/Modified

1. **`helm-charts/ecommerce-app/templates/hpa.yaml`** - HPA template with detailed comments
2. **`helm-charts/ecommerce-app/values.yaml`** - Added autoscaling configuration for all 6 microservices

## What is HPA?

Horizontal Pod Autoscaler automatically adjusts the number of pods in your deployment based on:
- CPU utilization
- Memory utilization
- Custom metrics (advanced)

## Prerequisites

### 1. Enable Metrics Server (Required!)

For Minikube:
```bash
minikube addons enable metrics-server
```

For regular Kubernetes cluster:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify metrics server is running:
```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods
```

### 2. Resource Requests Must Be Defined

HPA requires `resources.requests` to be defined in your deployment (already done in `values.yaml`):
```yaml
resources:
  requests:
    cpu: 250m      # Required for CPU-based autoscaling
    memory: 256Mi  # Required for memory-based autoscaling
  limits:
    cpu: 500m
    memory: 512Mi
```

## How to Enable HPA

### Option 1: Enable for Specific Service

Edit `values.yaml` and set `enabled: true`:

```yaml
microservices:
  offers:
    autoscaling:
      enabled: true  # ← Change this to true
      minReplicas: 2
      maxReplicas: 10
```

### Option 2: Enable via Helm Command

```bash
# Enable autoscaling for offers service
helm upgrade ecommerce-app helm-charts/ecommerce-app \
  --set microservices.offers.autoscaling.enabled=true

# Enable for multiple services
helm upgrade ecommerce-app helm-charts/ecommerce-app \
  --set microservices.offers.autoscaling.enabled=true \
  --set microservices.shoes.autoscaling.enabled=true \
  --set microservices.zuul.autoscaling.enabled=true
```

### Option 3: Enable for All Services

```bash
# Enable autoscaling for all microservices
helm upgrade ecommerce-app helm-charts/ecommerce-app \
  --set microservices.offers.autoscaling.enabled=true \
  --set microservices.shoes.autoscaling.enabled=true \
  --set microservices.wishlist.autoscaling.enabled=true \
  --set microservices.cart.autoscaling.enabled=true \
  --set microservices.zuul.autoscaling.enabled=true \
  --set microservices.ui.autoscaling.enabled=true
```

## Configuration Explained

### Key Settings in `values.yaml`

```yaml
autoscaling:
  enabled: false                          # Enable/disable HPA
  minReplicas: 2                          # Minimum pods (HA)
  maxReplicas: 10                         # Maximum pods (cost control)
  targetCPUUtilizationPercentage: 80      # Scale when CPU > 80%
  targetMemoryUtilizationPercentage: 80   # Scale when Memory > 80%
  
  behavior:
    scaleUp:                              # How to scale up
      stabilizationWindowSeconds: 0       # Scale up immediately
      policies:
        pods:
          value: 4                        # Add up to 4 pods
          periodSeconds: 60               # Per minute
        percent:
          value: 100                      # Or double (100%)
          periodSeconds: 60
      selectPolicy: "Max"                 # Use policy that scales most
    
    scaleDown:                            # How to scale down
      stabilizationWindowSeconds: 300     # Wait 5 min before scaling down
      policies:
        pods:
          value: 1                        # Remove 1 pod at a time
          periodSeconds: 60
        percent:
          value: 10                       # Or 10% of pods
          periodSeconds: 60
      selectPolicy: "Min"                 # Use policy that scales least
```

### Service-Specific Tuning

**Zuul (API Gateway)** - Most critical, conservative scaling:
- `minReplicas: 2` - Always 2+ for availability
- `maxReplicas: 6` - Gateways are resource-intensive
- `targetCPU: 70%` - Lower threshold (scale earlier)
- `scaleDown.stabilizationWindow: 600s` - Wait 10 min before scaling down

**Offers/Shoes (Spring Boot)** - Backend services:
- `minReplicas: 2`
- `maxReplicas: 10`
- `targetCPU: 80%` - Standard threshold

**Cart/Wishlist (Node/Python)** - Lightweight services:
- `minReplicas: 2`
- `maxReplicas: 8`
- `targetCPU: 75%` - Slightly more responsive

**UI (React)** - Frontend:
- `minReplicas: 2`
- `maxReplicas: 5` - UI is lightweight
- `targetCPU: 80%`

## Monitoring HPA

### Check HPA Status

```bash
# List all HPAs
kubectl get hpa

# Example output:
# NAME     REFERENCE          TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
# offers   Deployment/offers  45%/80%   2         10        2          5m
```

### Detailed HPA Information

```bash
# Describe specific HPA
kubectl describe hpa ecommerce-app-offers

# Watch HPA in real-time
kubectl get hpa -w
```

### Check Current Metrics

```bash
# View pod resource usage
kubectl top pods

# Example output:
# NAME                      CPU(cores)   MEMORY(bytes)
# offers-xxx-xxx            234m         412Mi
# offers-xxx-yyy            189m         398Mi
```

## Testing Autoscaling

### 1. Generate Load (CPU Test)

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Generate load on offers service
# Get the service URL first
ZUUL_URL=http://$(minikube ip):30999

# Send 10000 requests with 100 concurrent connections
ab -n 10000 -c 100 $ZUUL_URL/offer/offers

# Watch HPA scale up
kubectl get hpa -w
```

### 2. Simple Load Generator Pod

```bash
# Create a load generator
kubectl run load-generator --rm -i --tty --image=busybox --restart=Never -- /bin/sh

# Inside the pod, run:
while true; do wget -q -O- http://shoe:1002/shoes; done

# In another terminal, watch pods scale
kubectl get pods -w
kubectl get hpa -w
```

### 3. Load Testing with Hey

```bash
# Install hey (better than ab)
go install github.com/rakyll/hey@latest

# Or download binary
wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
chmod +x hey_linux_amd64

# Generate load
./hey_linux_amd64 -z 5m -c 50 http://$(minikube ip):30999/offer/offers

# -z 5m : run for 5 minutes
# -c 50 : 50 concurrent requests
```

## How HPA Calculates Desired Replicas

```
desiredReplicas = ceil[currentReplicas × (currentMetricValue / targetMetricValue)]
```

### Example:

Current state:
- Current replicas: 2
- Current CPU usage: 90%
- Target CPU: 80%

Calculation:
```
desiredReplicas = ceil[2 × (90 / 80)]
                = ceil[2 × 1.125]
                = ceil[2.25]
                = 3 pods
```

HPA will scale from 2 to 3 pods.

## Common Issues & Solutions

### Issue 1: "unable to get metrics for resource cpu"

**Cause**: Metrics server not installed or not ready

**Solution**:
```bash
# Enable metrics server
minikube addons enable metrics-server

# Wait for it to be ready
kubectl get deployment metrics-server -n kube-system
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system
```

### Issue 2: "missing request for cpu"

**Cause**: No resource requests defined in deployment

**Solution**: Already fixed in your `values.yaml` - all services have requests defined.

### Issue 3: "failed to get cpu utilization"

**Cause**: Pod just started, metrics not available yet

**Solution**: Wait 1-2 minutes for metrics to be collected.

### Issue 4: HPA shows "unknown" for TARGETS

**Cause**: Metrics not ready or pod not running

**Check**:
```bash
kubectl describe hpa ecommerce-app-offers
kubectl top pods
kubectl get pods
```

### Issue 5: Rapid scaling up and down (flapping)

**Cause**: Stabilization windows too short

**Solution**: Increase `scaleDown.stabilizationWindowSeconds`:
```yaml
scaleDown:
  stabilizationWindowSeconds: 600  # Wait 10 minutes
```

## Deployment Workflow with HPA

### 1. Initial Deployment (HPA Disabled)

```bash
# Deploy without autoscaling first
helm install ecommerce-app helm-charts/ecommerce-app
```

### 2. Verify Metrics Server

```bash
# Ensure metrics are working
kubectl top nodes
kubectl top pods

# Wait a minute if metrics not ready
```

### 3. Enable HPA

```bash
# Enable for critical services first (API Gateway)
helm upgrade ecommerce-app helm-charts/ecommerce-app \
  --set microservices.zuul.autoscaling.enabled=true

# Verify HPA is working
kubectl get hpa
kubectl describe hpa ecommerce-app-zuul
```

### 4. Monitor for 5-10 Minutes

```bash
# Watch HPA behavior
kubectl get hpa -w

# Check if it scales to minReplicas
kubectl get pods
```

### 5. Enable for Other Services

```bash
# Enable for all backend services
helm upgrade ecommerce-app helm-charts/ecommerce-app \
  --set microservices.zuul.autoscaling.enabled=true \
  --set microservices.offers.autoscaling.enabled=true \
  --set microservices.shoes.autoscaling.enabled=true \
  --set microservices.cart.autoscaling.enabled=true \
  --set microservices.wishlist.autoscaling.enabled=true \
  --set microservices.ui.autoscaling.enabled=true
```

## Production Recommendations

### 1. Always Use Odd Number of Replicas

For high availability with load balancing:
```yaml
minReplicas: 3  # Not 2
maxReplicas: 9  # Not 10
```

### 2. Set Appropriate Thresholds

- **API Gateway**: 60-70% (critical path, scale early)
- **Backend Services**: 70-80% (standard)
- **Frontend**: 80-85% (less critical)

### 3. Conservative Scale-Down

```yaml
scaleDown:
  stabilizationWindowSeconds: 300  # At least 5 minutes
```

### 4. Resource Requests = Actual Usage

Monitor actual resource usage and adjust requests:
```bash
kubectl top pods --containers
```

Update `values.yaml` based on real metrics.

### 5. Test Load Scenarios

Before production:
1. Generate expected peak load
2. Verify HPA scales appropriately
3. Check application performance during scaling
4. Verify scale-down happens correctly

## Advanced: Custom Metrics (Future Enhancement)

HPA can also scale based on custom metrics:
- Requests per second
- Queue depth
- Response time
- Custom business metrics

Example (requires Prometheus + metrics adapter):
```yaml
metrics:
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: "1000"
```

## Summary

✅ **Created**: Fully commented `hpa.yaml` template
✅ **Updated**: `values.yaml` with autoscaling config for all 6 services
✅ **Disabled by default**: Set `enabled: false` to avoid surprises
✅ **Ready to use**: Just set `enabled: true` and apply

**Next Steps**:
1. Enable metrics server: `minikube addons enable metrics-server`
2. Verify metrics: `kubectl top pods`
3. Enable HPA for one service to test
4. Monitor behavior and adjust thresholds
5. Enable for remaining services

**Documentation**: All settings are heavily commented in the template explaining what each field does and why.
