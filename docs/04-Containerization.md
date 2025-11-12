# Containerization with Docker

This guide explains how to containerize each microservice using Docker.

## Docker Basics

### What is Docker?

Docker is a platform for developing, shipping, and running applications in containers. Containers package an application with all its dependencies, ensuring it runs consistently across different environments.

### Key Concepts

- **Image**: A read-only template with application code and dependencies
- **Container**: A running instance of an image
- **Dockerfile**: A script that defines how to build an image
- **Registry**: A repository for storing and distributing images

## Dockerfile Structure

A Dockerfile contains instructions to build a Docker image:

```dockerfile
# Base image
FROM <base-image>

# Set working directory
WORKDIR /app

# Copy files
COPY <source> <destination>

# Run commands
RUN <command>

# Expose port
EXPOSE <port>

# Define startup command
CMD ["command", "arg1", "arg2"]
```

## Microservice Dockerfiles

### 1. Offers Microservice (Spring Boot)

**File**: `offers-microservice-spring-boot/Dockerfile`

```dockerfile
# Multi-stage build for smaller image size
FROM maven as build 
WORKDIR /app
COPY . .
RUN mvn install 

FROM openjdk:11.0.10-jre
WORKDIR /app
COPY --from=build /app/target/offers-0.0.1-SNAPSHOT.jar /app
EXPOSE 1001
CMD ["java","-jar","offers-0.0.1-SNAPSHOT.jar"]
```

#### Explanation

1. **Stage 1: Build**
   - `FROM maven as build`: Use Maven image for building
   - `WORKDIR /app`: Set working directory
   - `COPY . .`: Copy all source code
   - `RUN mvn install`: Build the application (creates JAR file)

2. **Stage 2: Runtime**
   - `FROM openjdk:11.0.10-jre`: Use lightweight JRE image
   - `COPY --from=build`: Copy JAR from build stage
   - `EXPOSE 1001`: Document that app uses port 1001
   - `CMD`: Start the Spring Boot application

#### Build Command
```bash
docker build -t offers-microservice:latest ./offers-microservice-spring-boot
```

---

### 2. Shoes Microservice (Spring Boot)

**File**: `shoes-microservice-spring-boot/Dockerfile`

```dockerfile
FROM maven as build 
WORKDIR /app
COPY . .
RUN mvn install 

FROM openjdk:11.0.10-jre
WORKDIR /app
COPY --from=build /app/target/shoes-0.0.1-SNAPSHOT.jar /app
EXPOSE 1002
CMD ["java","-jar","shoes-0.0.1-SNAPSHOT.jar"]
```

#### Build Command
```bash
docker build -t shoes-microservice:latest ./shoes-microservice-spring-boot
```

---

### 3. Cart Microservice (Node.js)

**File**: `cart-microservice-nodejs/Dockerfile`

```dockerfile
FROM node:14
WORKDIR /app 
COPY . .
RUN npm install
EXPOSE 1004
CMD ["node","index.js"]
```

#### Explanation

- `FROM node:14`: Use Node.js 14 base image
- `WORKDIR /app`: Set working directory
- `COPY . .`: Copy all application files
- `RUN npm install`: Install dependencies from package.json
- `EXPOSE 1004`: Document port usage
- `CMD ["node","index.js"]`: Start the Node.js server

#### Build Command
```bash
docker build -t cart-microservice:latest ./cart-microservice-nodejs
```

---

### 4. Wishlist Microservice (Python)

**File**: `wishlist-microservice-python/Dockerfile`

```dockerfile
FROM python:3
COPY . .
RUN pip install flask flask_cors
EXPOSE 1003
CMD ["python","index.py"]
```

#### Explanation

- `FROM python:3`: Use Python 3 base image
- `COPY . .`: Copy application files
- `RUN pip install flask flask_cors`: Install Python dependencies
- `EXPOSE 1003`: Document port usage
- `CMD ["python","index.py"]`: Start Flask application

#### Build Command
```bash
docker build -t wishlist-microservice:latest ./wishlist-microservice-python
```

---

### 5. Zuul API Gateway (Spring Boot)

**File**: `zuul-api-gateway/Dockerfile`

```dockerfile
FROM maven as build 
WORKDIR /app
COPY . .
RUN mvn install 

FROM openjdk:11.0.10-jre
WORKDIR /app
COPY --from=build /app/target/zuul-0.0.1-SNAPSHOT.jar /app
EXPOSE 9999
CMD ["java","-jar","zuul-0.0.1-SNAPSHOT.jar"]
```

#### Build Command
```bash
docker build -t zuul-api-gateway:latest ./zuul-api-gateway
```

---

### 6. UI Web App (React.js)

**File**: `ui-web-app-reactjs/Dockerfile`

```dockerfile
FROM node:14
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 8080
CMD ["npm","start"]
```

#### Explanation

- `FROM node:14`: Use Node.js 14 base image
- `WORKDIR /app`: Set working directory
- `COPY . .`: Copy all source files
- `RUN npm install`: Install dependencies
- `EXPOSE 8080`: Document port usage
- `CMD ["npm","start"]`: Start the webpack dev server

#### Build Command
```bash
docker build -t ui-web-app:latest ./ui-web-app-reactjs
```

---

## Build All Images

### Build Script

Create a script to build all images at once:

**File**: `build-images.sh`

```bash
#!/bin/bash

echo "Building Docker images for all microservices..."

# Build Offers Service
echo "Building Offers Microservice..."
docker build -t ecommerce-microservices-k8s-offers:latest ./offers-microservice-spring-boot

# Build Shoes Service
echo "Building Shoes Microservice..."
docker build -t ecommerce-microservices-k8s-shoes:latest ./shoes-microservice-spring-boot

# Build Cart Service
echo "Building Cart Microservice..."
docker build -t ecommerce-microservices-k8s-cart:latest ./cart-microservice-nodejs

# Build Wishlist Service
echo "Building Wishlist Microservice..."
docker build -t ecommerce-microservices-k8s-wishlist:latest ./wishlist-microservice-python

# Build Zuul Gateway
echo "Building Zuul API Gateway..."
docker build -t ecommerce-microservices-k8s-zuul:latest ./zuul-api-gateway

# Build UI Web App
echo "Building UI Web App..."
docker build -t ecommerce-microservices-k8s-ui:latest ./ui-web-app-reactjs

echo "All images built successfully!"
docker images | grep ecommerce-microservices-k8s
```

### Make Script Executable
```bash
chmod +x build-images.sh
```

### Run Build Script
```bash
./build-images.sh
```

---

## Docker Compose

For local development and testing, use Docker Compose to run all services together.

**File**: `docker-compose.yaml`

```yaml
services:
  ui:
    build: ./ui-web-app-reactjs
    ports:
      - 8080:8080
    depends_on:
      - zuul

  zuul:
    build: ./zuul-api-gateway
    ports:
      - 9999:9999
    depends_on:
      - offers
      - shoes
      - cart
      - wishlist

  shoes:
    build: ./shoes-microservice-spring-boot
    ports:
      - 1002:1002

  offers:
    build: ./offers-microservice-spring-boot
    ports:
      - 1001:1001

  cart:
    build: ./cart-microservice-nodejs
    ports:
      - 1004:1004

  wishlist:
    build: ./wishlist-microservice-python
    ports:
      - 1003:1003
```

### Docker Compose Commands

```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild and start
docker-compose up --build

# View running containers
docker-compose ps
```

---

## Testing Docker Images

### Test Individual Services

#### Test Offers Service
```bash
# Run container
docker run -d -p 1001:1001 --name offers-test ecommerce-microservices-k8s-offers:latest

# Test endpoint
curl http://localhost:1001/api/offers

# View logs
docker logs offers-test

# Stop and remove
docker stop offers-test
docker rm offers-test
```

#### Test Shoes Service
```bash
docker run -d -p 1002:1002 --name shoes-test ecommerce-microservices-k8s-shoes:latest
curl http://localhost:1002/api/shoes
docker stop shoes-test && docker rm shoes-test
```

#### Test Cart Service
```bash
docker run -d -p 1004:1004 --name cart-test ecommerce-microservices-k8s-cart:latest
curl http://localhost:1004/api/cart
docker stop cart-test && docker rm cart-test
```

#### Test Wishlist Service
```bash
docker run -d -p 1003:1003 --name wishlist-test ecommerce-microservices-k8s-wishlist:latest
curl http://localhost:1003/api/wishlist
docker stop wishlist-test && docker rm wishlist-test
```

---

## Best Practices

### 1. Use Multi-Stage Builds

Multi-stage builds reduce image size by separating build and runtime environments:

```dockerfile
# Build stage
FROM maven as build
WORKDIR /app
COPY . .
RUN mvn package

# Runtime stage
FROM openjdk:11-jre-slim
COPY --from=build /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

### 2. Minimize Layers

Combine commands to reduce layers:

```dockerfile
# Bad - Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git

# Good - Single layer
RUN apt-get update && \
    apt-get install -y curl git && \
    rm -rf /var/lib/apt/lists/*
```

### 3. Use .dockerignore

Create a `.dockerignore` file to exclude unnecessary files:

```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.DS_Store
target/
*.log
```

### 4. Don't Run as Root

Create a non-root user:

```dockerfile
FROM node:14
RUN useradd -m appuser
USER appuser
WORKDIR /home/appuser/app
COPY --chown=appuser:appuser . .
RUN npm install
CMD ["node", "index.js"]
```

### 5. Use Specific Tags

Avoid using `latest` tag in production:

```dockerfile
# Bad
FROM node:latest

# Good
FROM node:14.17.0-alpine
```

### 6. Health Checks

Add health checks to Dockerfiles:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

---

## Image Optimization

### Size Comparison

| Base Image | Size | Use Case |
|------------|------|----------|
| `openjdk:11` | ~600MB | Development |
| `openjdk:11-jre` | ~300MB | Production |
| `openjdk:11-jre-slim` | ~200MB | Optimized production |
| `node:14` | ~900MB | Development |
| `node:14-alpine` | ~100MB | Production |

### Using Alpine Images

Alpine Linux provides smaller base images:

```dockerfile
# Node.js with Alpine
FROM node:14-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["node", "index.js"]
```

---

## Pushing Images to Registry

### Docker Hub

```bash
# Login
docker login

# Tag image
docker tag ecommerce-microservices-k8s-offers:latest username/offers:latest

# Push image
docker push username/offers:latest
```

### Minikube Local Registry

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build images (they'll be available in Minikube)
docker build -t ecommerce-microservices-k8s-offers:latest ./offers-microservice-spring-boot

# Verify
minikube ssh
docker images
```

---

## Troubleshooting

### Build Fails

```bash
# View build output
docker build --no-cache -t myimage .

# Check build context size
du -sh .

# Use .dockerignore to exclude large directories
```

### Container Exits Immediately

```bash
# Check logs
docker logs <container-id>

# Run interactively
docker run -it <image> /bin/sh

# Override entrypoint
docker run -it --entrypoint /bin/sh <image>
```

### Network Issues

```bash
# Test connectivity
docker run --rm nicolaka/netshoot curl http://service:port

# Inspect network
docker network inspect bridge
```

---

## Next Steps

Proceed to [05-Kubernetes-Setup.md](./05-Kubernetes-Setup.md) to learn how to set up a Kubernetes cluster for deploying these containerized applications.
