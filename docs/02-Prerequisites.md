# Prerequisites and Installation

This guide covers all the tools and software you need to install before starting the project.

## System Requirements

### Minimum Hardware Requirements

- **CPU**: 2 cores or more
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 20GB free space
- **Operating System**: Linux, macOS, or Windows 10/11 with WSL2

### Recommended Setup

- **CPU**: 4 cores
- **RAM**: 8GB or more
- **Disk Space**: 50GB free space
- **Internet Connection**: Required for downloading images and packages

## Step 1: Install Docker

Docker is required for building and running containers.

### On Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### On Fedora/RHEL/CentOS

```bash
# Install Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

### On macOS

```bash
# Install using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://www.docker.com/products/docker-desktop
```

### On Windows

1. Download Docker Desktop from https://www.docker.com/products/docker-desktop
2. Install and restart your computer
3. Enable WSL2 backend if prompted

### Verify Docker Installation

```bash
# Check Docker version
docker --version

# Test Docker installation
docker run hello-world
```

## Step 2: Install Kubernetes (Minikube)

Minikube creates a local Kubernetes cluster for development and testing.

### Install kubectl (Kubernetes CLI)

#### On Linux

```bash
# Download latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

#### On macOS

```bash
# Using Homebrew
brew install kubectl

# Or download directly
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### On Windows

```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or download from:
# https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

### Install Minikube

#### On Linux

```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

#### On macOS

```bash
# Using Homebrew
brew install minikube

# Or download directly
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

#### On Windows

```powershell
# Using Chocolatey
choco install minikube

# Or download installer from:
# https://minikube.sigs.k8s.io/docs/start/
```

### Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### Minikube Useful Commands

```bash
# Check status
minikube status

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# Access Kubernetes dashboard
minikube dashboard

# SSH into minikube VM
minikube ssh
```

## Step 3: Install Helm

Helm is the package manager for Kubernetes.

### On Linux

```bash
# Download Helm installation script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# Make it executable
chmod 700 get_helm.sh

# Run the script
./get_helm.sh

# Verify installation
helm version
```

### On macOS

```bash
# Using Homebrew
brew install helm

# Verify installation
helm version
```

### On Windows

```powershell
# Using Chocolatey
choco install kubernetes-helm

# Using Scoop
scoop install helm
```

### Configure Helm

```bash
# Add stable chart repository
helm repo add stable https://charts.helm.sh/stable

# Add bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repositories
helm repo update

# List repositories
helm repo list
```

## Step 4: Install Additional Tools

### Install Git

```bash
# On Ubuntu/Debian
sudo apt-get install -y git

# On Fedora/RHEL
sudo dnf install -y git

# On macOS
brew install git

# Verify
git --version
```

### Install Java Development Kit (JDK 11)

Required for Spring Boot microservices.

```bash
# On Ubuntu/Debian
sudo apt-get install -y openjdk-11-jdk

# On Fedora/RHEL
sudo dnf install -y java-11-openjdk-devel

# On macOS
brew install openjdk@11

# Verify
java -version
javac -version
```

### Install Maven

Required for building Spring Boot applications.

```bash
# On Ubuntu/Debian
sudo apt-get install -y maven

# On Fedora/RHEL
sudo dnf install -y maven

# On macOS
brew install maven

# Verify
mvn -version
```

### Install Node.js and npm

Required for the Cart microservice and UI application.

```bash
# On Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# On Fedora/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# On macOS
brew install node

# Verify
node --version
npm --version
```

### Install Python 3 and pip

Required for the Wishlist microservice.

```bash
# On Ubuntu/Debian
sudo apt-get install -y python3 python3-pip

# On Fedora/RHEL
sudo dnf install -y python3 python3-pip

# On macOS (usually pre-installed)
brew install python3

# Verify
python3 --version
pip3 --version
```

## Step 5: Optional but Recommended Tools

### Install k9s (Kubernetes CLI UI)

```bash
# On Linux
curl -sS https://webinstall.dev/k9s | bash

# On macOS
brew install k9s

# Run k9s
k9s
```

### Install kubectx and kubens

```bash
# On Linux
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# On macOS
brew install kubectx

# Usage
kubectx           # List/switch contexts
kubens            # List/switch namespaces
```

### Install Visual Studio Code

```bash
# Download from https://code.visualstudio.com/

# Recommended Extensions:
# - Kubernetes
# - Docker
# - YAML
# - Helm Intellisense
```

## Verification Checklist

Before proceeding, verify all installations:

```bash
# Docker
docker --version
docker ps

# Kubernetes
kubectl version --client
minikube status

# Helm
helm version

# Git
git --version

# Java
java -version

# Maven
mvn -version

# Node.js
node --version
npm --version

# Python
python3 --version
pip3 --version
```

### Expected Output Example

```
Docker version 24.0.x
Kubernetes v1.28.x
Helm v3.13.x
Git 2.x.x
Java 11.0.x
Apache Maven 3.x.x
Node.js v18.x.x
npm 9.x.x
Python 3.x.x
pip 23.x.x
```

## Troubleshooting

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker
```

### Minikube Won't Start

```bash
# Delete and recreate cluster
minikube delete
minikube start --driver=docker

# Try different driver
minikube start --driver=virtualbox
```

### Insufficient Resources

```bash
# Start minikube with more resources
minikube start --cpus=4 --memory=8192
```

## Next Steps

Once all prerequisites are installed and verified, proceed to [03-Application-Structure.md](./03-Application-Structure.md) to understand the application architecture.
