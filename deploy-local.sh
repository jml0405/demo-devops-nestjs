#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="devsu-demo-nodejs"
IMAGE_TAG="local"
NAMESPACE="devsu-demo"

echo "========================================"
echo " Devsu Demo – Local Minikube Deploy"
echo "========================================"

echo "[1/6] Fixing Docker group membership..."
if ! groups "$USER" | grep -q docker; then
  sudo usermod -aG docker "$USER"
  echo "  ✓ Added $USER to docker group."
  echo "  ⚠  You need to log out and back in (or run 'newgrp docker') for this to take effect."
  echo "  Re-running with newgrp docker..."
  exec newgrp docker "$0" "$@"
else
  echo "  ✓ $USER already in docker group."
fi

echo "[2/6] Installing Terraform..."
if command -v terraform &>/dev/null; then
  echo "  ✓ Terraform $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])') already installed."
else
  sudo pacman -S --noconfirm terraform
  echo "  ✓ Terraform installed: $(terraform version --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
fi

echo "[3/6] Starting Minikube..."
if minikube status --format='{{.Host}}' 2>/dev/null | grep -q Running; then
  echo "  ✓ Minikube already running."
else
  minikube start --driver=docker --cpus=2 --memory=2048
  echo "  ✓ Minikube started."
fi

minikube addons enable ingress
echo "  ✓ Ingress addon enabled."

echo "[4/6] Building Docker image inside Minikube..."
eval "$(minikube docker-env)"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "${PROJECT_DIR}"
echo "  ✓ Image ${IMAGE_NAME}:${IMAGE_TAG} built."

echo "[5/6] Running Terraform apply..."
cd "${PROJECT_DIR}/terraform"

cat > terraform.tfvars <<EOF
image_name        = "${IMAGE_NAME}"
image_tag         = "${IMAGE_TAG}"
namespace         = "${NAMESPACE}"
database_user     = "user"
database_password = "password"
EOF

terraform init -upgrade
terraform apply -auto-approve

echo "  ✓ Terraform apply complete."

echo "[6/6] Verifying deployment..."
kubectl rollout status deployment/devsu-demo-deployment -n "${NAMESPACE}" --timeout=120s
echo ""
echo "  Pods:"
kubectl get pods -n "${NAMESPACE}" -o wide
echo ""
echo "  HPA:"
kubectl get hpa -n "${NAMESPACE}"
echo ""
echo "========================================="
echo " ✅  Deploy complete!"
echo ""
echo " Access the API:"
echo "   kubectl port-forward svc/devsu-demo-svc 8000:8000 -n ${NAMESPACE} &"
echo "   curl http://localhost:8000/api/users"
echo ""
echo " Or via Ingress (add to /etc/hosts first):"
echo "   $(minikube ip)  devsu-demo.local"
echo "   curl http://devsu-demo.local/api/users"
echo "========================================="
