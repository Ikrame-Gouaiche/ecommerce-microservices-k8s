#!/usr/bin/env bash
# Generates Kubernetes Deployment and Service manifests for the specified microservices.
set -euo pipefail

OUTPUT_DIR=${1:-"$(dirname "$0")"}

if [[ ! -d "${OUTPUT_DIR}" ]]; then
  echo "Output directory '${OUTPUT_DIR}' does not exist." >&2
  exit 1
fi

# Map of microservice name to its container port.

declare -A PORTS=(
  [shoes]=1002
  [wishlist]=1003
  [cart]=1004
  [ui]=8080
  [zuul]=9999
)

# Microservices to generate manifests for (skip 'offers' because it already exists).
SERVICES=(shoes cart wishlist zuul ui)

for svc in "${SERVICES[@]}"; do
  port=${PORTS[${svc}]}
  deployment_path="${OUTPUT_DIR}/${svc}-deployment.yaml"
  service_path="${OUTPUT_DIR}/${svc}-service.yaml"

  cat <<EOF >"${deployment_path}"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${svc}
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${svc}
  template:
    metadata:
      labels:
        app: ${svc}
    spec:
      containers:
        - name: ${svc}
          image: ecommerce-microservices-k8s-${svc}:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: ${port}
EOF

  cat <<EOF >"${service_path}"
apiVersion: v1
kind: Service
metadata:
  name: ${svc}
  namespace: ecommerce
spec:
  type: ClusterIP
  selector:
    app: ${svc}
  ports:
    - port: ${port}
      targetPort: ${port}
EOF

done

echo "Generated manifests in ${OUTPUT_DIR}: ${SERVICES[*]}"
