# E-commerce Microservices Deployment with Kubernetes and Helm

## Documentation Index

This documentation provides a comprehensive guide for deploying an e-commerce application built with microservices architecture using Kubernetes and Helm.

### 📚 Documentation Structure

1. **[01-Introduction.md](./01-Introduction.md)** - Project overview and architecture
2. **[02-Prerequisites.md](./02-Prerequisites.md)** - Required tools and installations
3. **[03-Application-Structure.md](./03-Application-Structure.md)** - Microservices details
4. **[04-Containerization.md](./04-Containerization.md)** - Docker containerization guide
5. **[05-Kubernetes-Setup.md](./05-Kubernetes-Setup.md)** - Kubernetes cluster setup
6. **[06-Helm-Introduction.md](./06-Helm-Introduction.md)** - Helm basics and concepts
7. **[07-Helm-Chart-Creation.md](./07-Helm-Chart-Creation.md)** - Creating Helm charts
8. **[08-Deployment-Guide.md](./08-Deployment-Guide.md)** - Step-by-step deployment
9. **[09-Testing-Verification.md](./09-Testing-Verification.md)** - Testing and verification
10. **[10-Updates-Rollback.md](./10-Updates-Rollback.md)** - Updates and rollback procedures
11. **[11-Chart-Repository.md](./11-Chart-Repository.md)** - Hosting charts with ChartMuseum
12. **[12-Troubleshooting.md](./12-Troubleshooting.md)** - Common issues and solutions
13. **[13-Best-Practices.md](./13-Best-Practices.md)** - Best practices and recommendations

### 🎯 Project Objectives

This project demonstrates:
- ✅ Helm tool manipulation and usage
- ✅ Creating and deploying multi-service Helm charts
- ✅ Automating deployment, updates, and rollback procedures
- ✅ Hosting and versioning Helm charts in a repository

### 🚀 Quick Start

For a quick deployment, follow these steps:

```bash
# 1. Install prerequisites (see 02-Prerequisites.md)
# 2. Start Kubernetes cluster
minikube start

# 3. Build Docker images
./scripts/build-images.sh

# 4. Deploy with Helm
helm install ecommerce ./helm-charts/ecommerce-app

# 5. Access the application
minikube service ui --url
```

### 📋 Project Information

- **Course**: Automatisation du déploiement d'applications microservices sur Kubernetes avec Helm
- **Professor**: Pr. Najat TISSIR
- **Institution**: ENSA KHOURIBGA
- **Technologies**: Kubernetes, Helm, Docker, Spring Boot, Node.js, Python, React.js

### 🏗️ Architecture Overview

The application consists of 6 microservices:
- **UI Web App** (React.js) - Frontend application
- **Zuul API Gateway** (Spring Boot) - API Gateway
- **Offers Service** (Spring Boot) - Offers management
- **Shoes Service** (Spring Boot) - Product catalog
- **Cart Service** (Node.js) - Shopping cart
- **Wishlist Service** (Python) - User wishlist

### 📞 Getting Help

If you encounter any issues:
1. Check the [Troubleshooting Guide](./12-Troubleshooting.md)
2. Review the specific section documentation
3. Verify prerequisites are correctly installed

---

**Note**: This documentation assumes a Linux/Unix environment. Windows users should adapt commands accordingly or use WSL2.
