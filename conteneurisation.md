# Microservices Deployment Guide

This guide explains how to deploy the e-commerce microservices architecture using Docker, Kubernetes, and Helm.

## Table of Contents
- [Prerequisites](#prerequisites)
- [1. Containerization](#1-containerization)
- [2. Kubernetes and Helm Setup](#2-kubernetes-and-helm-setup)
- [3. Deployment Steps](#3-deployment-steps)
- [4. Verification](#4-verification)
- [5. Additional Configuration](#5-additional-configuration)

## Prerequisites

- Docker installed and running
- Kubernetes cluster setup
- Helm installed
- kubectl configured to connect to your cluster

## 1. Containerization

Create Dockerfiles for each microservice:

### Offers Microservice (Spring Boot)
```dockerfile
FROM openjdk:11-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
```

### Shoes Microservice (Spring Boot)
```dockerfile
FROM openjdk:11-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
```

### Cart Microservice (Node.js)
```dockerfile
FROM node:14-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

### UI Web App (React.js)
```dockerfile
FROM node:14-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 80
CMD ["npm", "start"]
```

### Wishlist Microservice (Python)
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "index.py"]
```

## 2. Kubernetes and Helm Setup

### Create Helm Chart Structure
```bash
helm create ecommerce-app
```

### Helm Values (values.yaml)
```yaml
global:
  namespace: ecommerce

offers:
  name: offers-service
  replicaCount: 2
  image:
    repository: offers-microservice
    tag: latest
  service:
    port: 8080

shoes:
  name: shoes-service
  replicaCount: 2
  image:
    repository: shoes-microservice
    tag: latest
  service:
    port: 8080

cart:
  name: cart-service
  replicaCount: 2
  image:
    repository: cart-microservice
    tag: latest
  service:
    port: 3000

ui:
  name: ui-app
  replicaCount: 2
  image:
    repository: ui-web-app
    tag: latest
  service:
    port: 80

wishlist:
  name: wishlist-service
  replicaCount: 2
  image:
    repository: wishlist-microservice
    tag: latest
  service:
    port: 5000

gateway:
  name: api-gateway
  replicaCount: 2
  image:
    repository: zuul-api-gateway
    tag: latest
  service:
    port: 8080
```

## 3. Deployment Steps

### Build Applications
```bash
# Build Spring Boot applications
cd offers-microservice-spring-boot
./mvnw clean package
cd ../shoes-microservice-spring-boot
./mvnw clean package

# Build Node.js applications
cd ../cart-microservice-nodejs
npm install
cd ../ui-web-app-reactjs
npm install && npm run build
cd ..
```

### Build Docker Images
```bash
docker build -t offers-microservice:latest ./offers-microservice-spring-boot
docker build -t shoes-microservice:latest ./shoes-microservice-spring-boot
docker build -t cart-microservice:latest ./cart-microservice-nodejs
docker build -t ui-web-app:latest ./ui-web-app-reactjs
docker build -t wishlist-microservice:latest ./wishlist-microservice-python
docker build -t zuul-api-gateway:latest ./zuul-api-gateway
```

### Deploy to Kubernetes
```bash
# Create namespace
kubectl create namespace ecommerce

# Install Helm chart
helm install ecommerce-app ./ecommerce-app -n ecommerce
```

## 4. Verification

Check deployment status:
```bash
# Check all resources
kubectl get all -n ecommerce

# Check pods
kubectl get pods -n ecommerce

# Check services
kubectl get svc -n ecommerce
```

## 5. Additional Configuration

### Ingress Configuration
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
spec:
  rules:
  - host: ecommerce.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ui-app
            port:
              number: 80
      - path: /api/offers
        pathType: Prefix
        backend:
          service:
            name: offers-service
            port:
              number: 8080
```

### Additional Considerations

1. **Security**
   - Implement network policies
   - Configure TLS/SSL
   - Set up authentication and authorization
   - Use secrets for sensitive data

2. **Monitoring and Logging**
   - Set up Prometheus for metrics
   - Configure Grafana for visualization
   - Implement ELK stack for logging
   - Configure health checks and readiness probes

3. **Scaling and Reliability**
   - Configure HPA (Horizontal Pod Autoscaling)
   - Implement circuit breakers
   - Set up proper resource limits and requests
   - Configure pod disruption budgets

4. **CI/CD**
   - Set up automated build pipelines
   - Configure deployment strategies
   - Implement automated testing
   - Set up continuous monitoring

5. **Storage**
   - Configure persistent volumes if needed
   - Set up backup strategies
   - Implement data retention policies

Remember to adjust all configurations according to your specific requirements and environment.