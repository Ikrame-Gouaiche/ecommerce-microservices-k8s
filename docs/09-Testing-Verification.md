# Testing and Verification

This guide covers comprehensive testing and verification procedures for the deployed e-commerce application.

## Table of Contents

1. [Pre-Deployment Testing](#pre-deployment-testing)
2. [Post-Deployment Verification](#post-deployment-verification)
3. [Functional Testing](#functional-testing)
4. [Performance Testing](#performance-testing)
5. [Integration Testing](#integration-testing)
6. [Monitoring and Observability](#monitoring-and-observability)

## Pre-Deployment Testing

### Helm Chart Validation

```bash
# Lint the chart
helm lint ./helm-charts/ecommerce-app

# Dry run installation
helm install ecommerce ./helm-charts/ecommerce-app --dry-run --debug

# Template rendering
helm template ecommerce ./helm-charts/ecommerce-app > rendered-manifests.yaml

# Validate generated manifests
kubectl apply --dry-run=client -f rendered-manifests.yaml
```

### Docker Image Testing

```bash
# Test each image individually
docker run --rm -p 1001:1001 ecommerce-microservices-k8s-offers:latest
docker run --rm -p 1002:1002 ecommerce-microservices-k8s-shoes:latest
docker run --rm -p 1004:1004 ecommerce-microservices-k8s-cart:latest
docker run --rm -p 1003:1003 ecommerce-microservices-k8s-wishlist:latest
docker run --rm -p 9999:9999 ecommerce-microservices-k8s-zuul:latest
docker run --rm -p 8080:8080 ecommerce-microservices-k8s-ui:latest

# Test endpoints
curl http://localhost:1001/api/offers
curl http://localhost:1002/api/shoes
```

## Post-Deployment Verification

### Check Deployment Status

```bash
# Verify Helm release
helm status ecommerce
helm list

# Check all Kubernetes resources
kubectl get all

# Verify deployments are ready
kubectl get deployments
kubectl rollout status deployment/offers
kubectl rollout status deployment/shoes
kubectl rollout status deployment/cart
kubectl rollout status deployment/wishlist
kubectl rollout status deployment/zuul
kubectl rollout status deployment/ui
```

### Verify Pods

```bash
# Check pod status
kubectl get pods

# Ensure all pods are Running
kubectl get pods | grep -v Running | grep -v NAME

# Check pod readiness
kubectl get pods -o wide

# Verify no restarts
kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount
```

### Verify Services

```bash
# List services
kubectl get services

# Check endpoints (should have pod IPs)
kubectl get endpoints

# Verify service selectors match pod labels
kubectl describe service offers
kubectl get pods -l app=offers
```

### Check Resource Usage

```bash
# Enable metrics server (if not already)
minikube addons enable metrics-server

# Wait for metrics to be available
sleep 60

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods

# Sort by CPU usage
kubectl top pods --sort-by=cpu

# Sort by memory usage
kubectl top pods --sort-by=memory
```

## Functional Testing

### Test Individual Microservices

#### Test Offers Service

```bash
# Port forward the service
kubectl port-forward service/offers 1001:1001 &

# Test API endpoints
curl http://localhost:1001/api/offers
curl http://localhost:1001/api/offers/1

# If Spring Boot Actuator is enabled
curl http://localhost:1001/actuator/health
curl http://localhost:1001/actuator/info

# Stop port forward
kill %1
```

#### Test Shoes Service

```bash
# Port forward
kubectl port-forward service/shoes 1002:1002 &

# Test endpoints
curl http://localhost:1002/api/shoes
curl http://localhost:1002/api/shoes/1

# Health check
curl http://localhost:1002/actuator/health

# Cleanup
kill %1
```

#### Test Cart Service

```bash
# Port forward
kubectl port-forward service/cart 1004:1004 &

# Test endpoints
curl http://localhost:1004/api/cart

# Add item to cart
curl -X POST http://localhost:1004/api/cart \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}'

# Cleanup
kill %1
```

#### Test Wishlist Service

```bash
# Port forward
kubectl port-forward service/wishlist 1003:1003 &

# Test endpoints
curl http://localhost:1003/api/wishlist

# Add to wishlist
curl -X POST http://localhost:1003/api/wishlist \
  -H "Content-Type: application/json" \
  -d '{"productId": 1}'

# Cleanup
kill %1
```

#### Test API Gateway

```bash
# Port forward
kubectl port-forward service/zuul 9999:9999 &

# Test routing to different services
curl http://localhost:9999/api/offers
curl http://localhost:9999/api/shoes
curl http://localhost:9999/api/cart
curl http://localhost:9999/api/wishlist

# Cleanup
kill %1
```

#### Test UI Application

```bash
# Get UI URL
minikube service ui --url

# Or port forward
kubectl port-forward service/ui 8080:8080 &

# Test in browser or with curl
curl http://localhost:8080

# Cleanup
kill %1
```

### Internal Service Communication Test

```bash
# Create a debug pod inside the cluster
kubectl run debug --image=curlimages/curl -it --rm --restart=Never -- sh

# Inside the debug pod, test internal DNS and communication:
# curl http://offers:1001/api/offers
# curl http://shoes:1002/api/shoes
# curl http://cart:1004/api/cart
# curl http://wishlist:1003/api/wishlist
# curl http://zuul:9999/api/offers
# curl http://ui:8080

# Exit the debug pod (it will be automatically deleted)
exit
```

### End-to-End Flow Test

Create a test script to verify the complete flow:

```bash
cat > e2e-test.sh <<'EOF'
#!/bin/bash

echo "==================================="
echo "E-commerce E2E Flow Test"
echo "==================================="

# Get UI URL
UI_URL=$(minikube service ui --url)

echo "1. Testing UI accessibility..."
if curl -s -o /dev/null -w "%{http_code}" $UI_URL | grep -q "200"; then
  echo "✅ UI is accessible"
else
  echo "❌ UI is not accessible"
  exit 1
fi

# Test via API Gateway
echo "2. Testing API Gateway..."
kubectl port-forward service/zuul 9999:9999 &
PF_PID=$!
sleep 2

if curl -s http://localhost:9999/api/offers | grep -q "offers\\|\\[\\]"; then
  echo "✅ API Gateway routing works"
else
  echo "❌ API Gateway routing failed"
  kill $PF_PID
  exit 1
fi

echo "3. Testing all microservices via Gateway..."
for endpoint in offers shoes cart wishlist; do
  if curl -s http://localhost:9999/api/$endpoint > /dev/null; then
    echo "✅ $endpoint service responds"
  else
    echo "❌ $endpoint service failed"
  fi
done

kill $PF_PID

echo "==================================="
echo "E2E Tests Complete"
echo "==================================="
EOF

chmod +x e2e-test.sh
./e2e-test.sh
```

## Performance Testing

### Load Testing with Apache Bench

```bash
# Install Apache Bench (if not installed)
# Ubuntu/Debian: sudo apt-get install apache2-utils
# macOS: brew install apache2-utils

# Get service URL
URL=$(minikube service ui --url)

# Simple load test
ab -n 1000 -c 10 $URL/

# Test specific endpoint
kubectl port-forward service/offers 1001:1001 &
ab -n 1000 -c 50 http://localhost:1001/api/offers
kill %1
```

### Load Testing with hey

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Or download binary from https://github.com/rakyll/hey

# Run load test
kubectl port-forward service/offers 1001:1001 &
hey -n 1000 -c 50 http://localhost:1001/api/offers
kill %1
```

### Stress Testing

```bash
# Monitor resources during stress test
watch -n 1 kubectl top pods

# In another terminal, run stress test
kubectl port-forward service/zuul 9999:9999 &
hey -n 10000 -c 100 -q 10 http://localhost:9999/api/offers
kill %1
```

## Integration Testing

### Service Discovery Test

```bash
# Test DNS resolution inside cluster
kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup offers
kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup shoes
kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup zuul
```

### Network Policy Testing

```bash
# Test connectivity between services
kubectl run -it --rm test --image=curlimages/curl --restart=Never -- \
  curl -v http://offers:1001/api/offers

# Test gateway can reach all services
POD=$(kubectl get pod -l app=zuul -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- curl http://offers:1001/api/offers
kubectl exec -it $POD -- curl http://shoes:1002/api/shoes
kubectl exec -it $POD -- curl http://cart:1004/api/cart
kubectl exec -it $POD -- curl http://wishlist:1003/api/wishlist
```

## Monitoring and Observability

### View Logs

```bash
# View logs for all instances of a service
kubectl logs -l app=offers --tail=100

# Follow logs in real-time
kubectl logs -l app=offers -f

# View logs from previous container (if crashed)
kubectl logs <pod-name> --previous

# View logs from specific container in pod
kubectl logs <pod-name> -c <container-name>

# View logs with timestamps
kubectl logs <pod-name> --timestamps=true
```

### Aggregate Logs

```bash
# Create a script to view logs from all services
cat > view-all-logs.sh <<'EOF'
#!/bin/bash

SERVICES="offers shoes cart wishlist zuul ui"

for service in $SERVICES; do
  echo "===================="
  echo "Logs for $service"
  echo "===================="
  kubectl logs -l app=$service --tail=20
  echo ""
done
EOF

chmod +x view-all-logs.sh
./view-all-logs.sh
```

### Events Monitoring

```bash
# View all events
kubectl get events --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events --watch

# Filter events by type
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Normal
```

### Health Checks

Create a health check script:

```bash
cat > health-check.sh <<'EOF'
#!/bin/bash

echo "==================================="
echo "Health Check Report"
echo "==================================="

# Check pod health
echo "Pod Status:"
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?\(@.type==\"Ready\"\)].status

# Check deployment health
echo ""
echo "Deployment Status:"
kubectl get deployments -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.spec.replicas

# Check service endpoints
echo ""
echo "Service Endpoints:"
for svc in offers shoes cart wishlist zuul ui; do
  endpoints=$(kubectl get endpoints $svc -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
  echo "$svc: $endpoints endpoint(s)"
done

# Check resource usage
echo ""
echo "Resource Usage:"
kubectl top pods 2>/dev/null || echo "Metrics not available (enable metrics-server)"

echo "==================================="
EOF

chmod +x health-check.sh
./health-check.sh
```

### Metrics Collection

```bash
# Enable metrics server
minikube addons enable metrics-server

# Wait for metrics to be available
sleep 60

# Get current metrics
kubectl top nodes
kubectl top pods

# Continuous monitoring
watch -n 5 kubectl top pods
```

## Automated Testing Script

Create a comprehensive automated test:

```bash
cat > automated-test.sh <<'EOF'
#!/bin/bash

set -e

echo "========================================="
echo "Automated E-commerce Application Test"
echo "========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
  local test_name=$1
  local test_command=$2
  
  echo -n "Testing $test_name... "
  if eval $test_command > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
  fi
}

# Test 1: Helm release exists
run_test "Helm release" "helm status ecommerce"

# Test 2: All deployments are ready
run_test "Deployments ready" "kubectl wait --for=condition=available --timeout=60s deployment --all"

# Test 3: All pods are running
run_test "All pods running" "[ \$(kubectl get pods --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l) -eq 0 ]"

# Test 4: Services have endpoints
run_test "Service endpoints" "[ \$(kubectl get endpoints -o json | jq '.items[].subsets | length' | grep -c 0) -eq 0 ]"

# Test 5: UI service is accessible
run_test "UI accessible" "curl -s -o /dev/null -w '%{http_code}' \$(minikube service ui --url) | grep -q 200"

# Test 6: Internal service communication
run_test "Service discovery" "kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup offers"

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "========================================="

if [ $TESTS_FAILED -gt 0 ]; then
  exit 1
else
  exit 0
fi
EOF

chmod +x automated-test.sh
./automated-test.sh
```

## Debugging Failed Tests

### Pod Not Starting

```bash
# Describe pod to see events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check previous logs if restarted
kubectl logs <pod-name> --previous

# Get pod YAML
kubectl get pod <pod-name> -o yaml
```

### Service Not Responding

```bash
# Check if service exists
kubectl get service <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Verify selector matches pods
kubectl describe service <service-name>
kubectl get pods -l app=<service-name>

# Test from inside cluster
kubectl run test --image=curlimages/curl -it --rm --restart=Never -- \
  curl -v http://<service-name>:<port>
```

### Network Issues

```bash
# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash

# Inside debug pod:
# ping offers
# curl http://offers:1001/api/offers
# nslookup offers
# traceroute offers
```

## Test Report Generation

```bash
cat > generate-test-report.sh <<'EOF'
#!/bin/bash

REPORT_FILE="test-report-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "E-commerce Application Test Report"
  echo "Generated: $(date)"
  echo "======================================"
  echo ""
  
  echo "1. Helm Release Status"
  echo "----------------------"
  helm status ecommerce
  echo ""
  
  echo "2. Pod Status"
  echo "-------------"
  kubectl get pods -o wide
  echo ""
  
  echo "3. Service Status"
  echo "-----------------"
  kubectl get services
  echo ""
  
  echo "4. Resource Usage"
  echo "-----------------"
  kubectl top pods 2>/dev/null || echo "Metrics not available"
  echo ""
  
  echo "5. Recent Events"
  echo "----------------"
  kubectl get events --sort-by='.lastTimestamp' | tail -20
  echo ""
  
  echo "6. Service Endpoints"
  echo "--------------------"
  kubectl get endpoints
  echo ""
  
} > $REPORT_FILE

echo "Test report generated: $REPORT_FILE"
cat $REPORT_FILE
EOF

chmod +x generate-test-report.sh
./generate-test-report.sh
```

## Next Steps

Proceed to [10-Updates-Rollback.md](./10-Updates-Rollback.md) to learn about updating applications and performing rollbacks.
