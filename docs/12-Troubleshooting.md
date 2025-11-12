# Troubleshooting Guide

Common issues and solutions when deploying microservices with Helm on Kubernetes.

## General Troubleshooting Commands

```bash
# Check everything
kubectl get all
helm list
minikube status

# Describe resources
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl describe service <service-name>

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# View events
kubectl get events --sort-by='.lastTimestamp'

# Resource usage
kubectl top nodes
kubectl top pods
```

## Common Issues

### 1. ImagePullBackOff / ErrImagePull

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS             RESTARTS   AGE
# offers-xxx-xxx          0/1     ImagePullBackOff   0          2m
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
# Look for: Failed to pull image ... image not found
```

**Solutions:**

**A. Image doesn't exist in Minikube's Docker**
```bash
# Verify you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Check if image exists
docker images | grep ecommerce-microservices-k8s

# Rebuild image if missing
docker build -t ecommerce-microservices-k8s-offers:latest \
  ./offers-microservice-spring-boot
```

**B. Wrong imagePullPolicy**
```bash
# Update to use local images
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set global.imagePullPolicy=IfNotPresent

# Or edit values.yaml:
# global:
#   imagePullPolicy: IfNotPresent
```

**C. Wrong image name or tag**
```bash
# Check values.yaml
cat helm-charts/ecommerce-app/values.yaml | grep -A 3 "image:"

# Verify image name matches
docker images | grep offers

# Update if needed
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.image.repository=correct-image-name
```

### 2. CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS              RESTARTS   AGE
# offers-xxx-xxx          0/1     CrashLoopBackOff    5          5m
```

**Diagnosis:**
```bash
# Check logs
kubectl logs <pod-name>

# Check previous logs if pod restarted
kubectl logs <pod-name> --previous

# Describe pod for details
kubectl describe pod <pod-name>
```

**Common Causes & Solutions:**

**A. Application Error**
```bash
# Check logs for stack traces
kubectl logs <pod-name> --tail=100

# Common Java errors:
# - Port already in use: Check port configuration
# - Class not found: Rebuild with correct dependencies
# - Connection refused: Check service dependencies
```

**B. Missing Environment Variables**
```bash
# Add environment variables
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.env.DATABASE_URL=postgres://db:5432
```

**C. Insufficient Resources**
```bash
# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 Limits

# Reduce resource requests
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.requests.memory=128Mi \
  --set microservices.offers.resources.requests.cpu=100m
```

**D. Wrong Port Configuration**
```bash
# Verify port in Dockerfile matches deployment
# Dockerfile: EXPOSE 1001
# deployment.yaml: containerPort: 1001
# values.yaml: targetPort: 1001
```

### 3. Pods Stuck in Pending

**Symptoms:**
```bash
kubectl get pods
# NAME                    READY   STATUS    RESTARTS   AGE
# offers-xxx-xxx          0/1     Pending   0          10m
```

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
# Look for: FailedScheduling events
```

**Common Causes & Solutions:**

**A. Insufficient Node Resources**
```bash
# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check what's requesting resources
kubectl top pods

# Solution: Reduce resource requests or add more nodes
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.requests.memory=64Mi \
  --set microservices.offers.resources.requests.cpu=50m
```

**B. PersistentVolumeClaim Issues**
```bash
# Check PVC status
kubectl get pvc

# Describe PVC
kubectl describe pvc <pvc-name>

# For Minikube, enable storage provisioner
minikube addons enable storage-provisioner
```

### 4. Service Not Accessible

**Symptoms:**
- Cannot access service via NodePort
- Service returns connection refused
- Endpoints are empty

**Diagnosis:**
```bash
# Check service
kubectl get svc

# Check endpoints
kubectl get endpoints

# Describe service
kubectl describe svc <service-name>
```

**Solutions:**

**A. No Endpoints**
```bash
# Check if pods are ready
kubectl get pods -l app=<service-name>

# Verify selector matches pod labels
kubectl describe svc <service-name> | grep Selector
kubectl get pods -l app=<service-name> --show-labels

# If mismatch, update service selector
```

**B. Wrong Port**
```bash
# Verify ports
kubectl get svc <service-name> -o yaml

# Test from inside cluster
kubectl run test --image=curlimages/curl -it --rm --restart=Never -- \
  curl http://<service-name>:<port>
```

**C. NodePort not accessible**
```bash
# Get minikube IP
minikube ip

# Get NodePort
kubectl get svc ui -o jsonpath='{.spec.ports[0].nodePort}'

# Use minikube service command
minikube service ui --url

# Or port-forward
kubectl port-forward svc/ui 8080:8080
```

### 5. Helm Installation Fails

**Symptoms:**
```bash
helm install ecommerce ./helm-charts/ecommerce-app
# Error: ... (various errors)
```

**Solutions:**

**A. Chart Validation Errors**
```bash
# Lint chart
helm lint ./helm-charts/ecommerce-app

# Fix reported errors, common issues:
# - Invalid YAML syntax
# - Missing required fields
# - Template rendering errors
```

**B. Release Already Exists**
```bash
# List releases
helm list

# Uninstall existing release
helm uninstall ecommerce

# Or use upgrade --install
helm upgrade --install ecommerce ./helm-charts/ecommerce-app
```

**C. Invalid Values**
```bash
# Dry run to check
helm install ecommerce ./helm-charts/ecommerce-app --dry-run --debug

# Verify values
helm show values ./helm-charts/ecommerce-app
```

### 6. Helm Upgrade Fails

**Symptoms:**
```bash
helm upgrade ecommerce ./helm-charts/ecommerce-app
# Error: UPGRADE FAILED: ...
```

**Solutions:**

**A. Check Helm Diff**
```bash
# Install diff plugin if not installed
helm plugin install https://github.com/databus23/helm-diff

# See what would change
helm diff upgrade ecommerce ./helm-charts/ecommerce-app
```

**B. Rollback if Upgrade Fails**
```bash
# View history
helm history ecommerce

# Rollback to previous version
helm rollback ecommerce

# Or to specific revision
helm rollback ecommerce 1
```

**C. Force Upgrade**
```bash
# Force upgrade (use with caution)
helm upgrade ecommerce ./helm-charts/ecommerce-app --force
```

### 7. DNS Resolution Issues

**Symptoms:**
- Services can't communicate
- nslookup fails inside pods

**Diagnosis:**
```bash
# Test DNS from inside cluster
kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup offers

# Check CoreDNS pods
kubectl get pods -n kube-system | grep coredns
```

**Solutions:**

**A. CoreDNS Not Running**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

**B. Wrong Service Name**
```bash
# Use correct FQDN
# Same namespace: <service-name>
# Different namespace: <service-name>.<namespace>.svc.cluster.local

# Example:
curl http://offers:1001/api/offers  # Same namespace
curl http://offers.default.svc.cluster.local:1001/api/offers  # Full FQDN
```

### 8. Resource Quota Exceeded

**Symptoms:**
```bash
kubectl describe pod <pod-name>
# Error: exceeded quota
```

**Solutions:**
```bash
# Check quotas
kubectl get resourcequota

# Describe quota
kubectl describe resourcequota <quota-name>

# Reduce resource requests
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.memory=256Mi
```

### 9. Persistent Volume Issues

**Symptoms:**
- PVC stuck in Pending
- Pod can't mount volume

**Solutions:**
```bash
# Check PVCs
kubectl get pvc

# Check PVs
kubectl get pv

# For Minikube, enable storage addon
minikube addons enable storage-provisioner

# Check storage class
kubectl get storageclass

# Describe PVC for errors
kubectl describe pvc <pvc-name>
```

### 10. Minikube Issues

**A. Minikube Won't Start**
```bash
# Delete and recreate
minikube delete
minikube start --driver=docker

# Try different driver
minikube start --driver=virtualbox

# Increase resources
minikube start --cpus=4 --memory=8192
```

**B. Minikube Running Out of Space**
```bash
# SSH into minikube
minikube ssh

# Clean up Docker
docker system prune -a -f

# Exit minikube
exit

# Or increase disk size
minikube delete
minikube start --disk-size=40g
```

**C. Docker Daemon Issues**
```bash
# Reset to host Docker
eval $(minikube docker-env -u)

# Verify
docker ps

# Re-enable Minikube Docker
eval $(minikube docker-env)
```

## Debugging Workflow

### Step-by-Step Debugging Process

```bash
# 1. Check pod status
kubectl get pods

# 2. Describe problematic pod
kubectl describe pod <pod-name>

# 3. Check logs
kubectl logs <pod-name>

# 4. Check previous logs if restarted
kubectl logs <pod-name> --previous

# 5. Check events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# 6. Exec into pod if running
kubectl exec -it <pod-name> -- /bin/sh

# 7. Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh

# 8. Check service and endpoints
kubectl get svc
kubectl get endpoints

# 9. Verify Helm release
helm status ecommerce
helm get values ecommerce

# 10. Check resource usage
kubectl top pods
kubectl top nodes
```

## Useful Debugging Tools

### Create Debug Pod

```bash
# Create a debug pod with utilities
kubectl run debug --image=nicolaka/netshoot -it --rm --restart=Never -- bash

# Inside debug pod, you have access to:
# - curl, wget
# - dig, nslookup
# - ping, traceroute
# - netstat, ss
# - tcpdump
```

### Port Forwarding for Local Testing

```bash
# Forward multiple ports
kubectl port-forward pod/<pod-name> 1001:1001 &
kubectl port-forward svc/offers 1001:1001 &

# Kill all port-forwards
killall kubectl
```

### Watch Resources

```bash
# Watch pods
watch kubectl get pods

# Watch events
watch 'kubectl get events --sort-by=.lastTimestamp | tail -20'

# Watch with k9s (if installed)
k9s
```

## Log Analysis

### Common Log Patterns

**Java Spring Boot:**
```bash
# Application started successfully
grep "Started.*Application in" <log>

# Port binding
grep "Tomcat started on port" <log>

# Errors
grep "ERROR" <log>
grep "Exception" <log>
```

**Node.js:**
```bash
# Server started
grep "listening on port" <log>

# Errors
grep "Error:" <log>
grep "ECONNREFUSED" <log>
```

**Python Flask:**
```bash
# Server started
grep "Running on" <log>

# Errors
grep "Traceback" <log>
grep "Error" <log>
```

## Performance Issues

### High CPU Usage

```bash
# Check CPU usage
kubectl top pods

# Check limits
kubectl describe pod <pod-name> | grep -A 3 Limits

# Increase CPU limit
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.cpu=1000m
```

### High Memory Usage

```bash
# Check memory usage
kubectl top pods

# Check for OOMKilled
kubectl describe pod <pod-name> | grep -i oom

# Increase memory limit
helm upgrade ecommerce ./helm-charts/ecommerce-app \
  --set microservices.offers.resources.limits.memory=1Gi
```

### Slow Startup

```bash
# Check startup time in logs
kubectl logs <pod-name> | grep -i started

# Increase startup timeout
# Add to deployment:
# livenessProbe:
#   initialDelaySeconds: 60
# readinessProbe:
#   initialDelaySeconds: 30
```

## Emergency Procedures

### Force Delete Pod

```bash
# If pod won't delete
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Reset Deployment

```bash
# Restart deployment
kubectl rollout restart deployment/<deployment-name>

# Or delete pods to force recreation
kubectl delete pods -l app=<service-name>
```

### Emergency Helm Rollback

```bash
# Immediate rollback
helm rollback ecommerce --wait=false

# Force rollback
helm rollback ecommerce --force
```

### Clean Slate Restart

```bash
# Nuclear option: delete everything and start fresh
helm uninstall ecommerce
kubectl delete all --all
minikube stop
minikube delete
minikube start
eval $(minikube docker-env)
./build-all-images.sh
helm install ecommerce ./helm-charts/ecommerce-app
```

## Preventive Measures

1. **Always lint charts**: `helm lint ./chart`
2. **Dry run before install**: `helm install --dry-run --debug`
3. **Use resource limits**: Prevent resource exhaustion
4. **Monitor logs**: `kubectl logs -f`
5. **Set up alerts**: For critical issues
6. **Test in staging**: Before production
7. **Document configurations**: Keep track of changes
8. **Regular backups**: Of Helm releases and configs

## Getting Help

### Check Documentation

```bash
# Helm help
helm help
helm <command> --help

# Kubectl help
kubectl --help
kubectl <command> --help

# Minikube help
minikube --help
```

### Community Resources

- Kubernetes Slack: https://kubernetes.slack.com
- Helm Slack: https://slack.helm.sh
- Stack Overflow: kubernetes, helm tags
- GitHub Issues: For specific tools

## Next Steps

Proceed to [13-Best-Practices.md](./13-Best-Practices.md) for recommended practices and guidelines.
