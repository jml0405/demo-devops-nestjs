# Demo DevOps NodeJs

A simple REST API application used for the Devsu DevOps technical test.  
Built with **Node.js 18**, **Express**, and **SQLite** (via Sequelize).

---

## Architecture

```mermaid
flowchart TD
    Dev[Developer] -->|git push / PR| GH[GitHub]

    subgraph CI ["GitHub Actions – CI/CD Pipeline"]
        direction TB
        B[Code Build\nnpm ci] --> L[Static Analysis\nESLint]
        B --> T[Unit Tests\nJest]
        T --> C[Code Coverage\nJest --coverage]
        L & C --> D[Docker Build & Push\nDocker Hub]
        D --> K[Deploy to Kubernetes\nkubectl apply]
    end

    GH --> CI

    subgraph K8S ["Kubernetes Cluster (devsu-demo namespace)"]
        direction LR
        ING[Ingress\nnginx] --> SVC[Service\nClusterIP :8000]
        SVC --> P1[Pod 1]
        SVC --> P2[Pod 2]
        HPA[HPA\nmin:2 / max:5] -.scales.-> DEP[Deployment]
        CM[ConfigMap] -.env.-> P1 & P2
        SEC[Secret] -.env.-> P1 & P2
    end

    K --> K8S
```

---

## Getting Started

### Prerequisites

- Node.js 18.15.0
- Docker 24+
- kubectl + minikube (for local k8s)

### Installation

```bash
git clone https://github.com/jml0405/devsu-demo-devops-nodejs.git
cd devsu-demo-devops-nodejs
npm ci
```

### Running locally

```bash
npm run start
# API available at http://localhost:8000/api/users
```

### Running tests

```bash
# Unit tests
npm test

# Tests with coverage report (must pass 80% threshold)
npm run test:coverage

# Static code analysis
npm run lint
```

---

## Docker

### Build

```bash
docker build -t devsu-demo-nodejs .
```

### Run

```bash
docker run -p 8000:8000 \
  -e DATABASE_NAME="./dev.sqlite" \
  -e DATABASE_USER="user" \
  -e DATABASE_PASSWORD="password" \
  devsu-demo-nodejs
```

### Test

```bash
curl http://localhost:8000/api/users
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{"dni":"12345678","name":"Jane Doe"}'
```

---

## CI/CD Pipeline

The pipeline is split into two separate workflows:

### [`ci.yml`](.github/workflows/ci.yml) – Continuous Integration

Runs on every **push** and **pull request** to `main`.

| Stage | Tool | Notes |
|---|---|---|
| Code Build | `npm ci` | Installs dependencies |
| Static Analysis | ESLint | Zero warnings allowed |
| Unit Tests | Jest | All tests must pass |
| Code Coverage | Jest `--coverage` | ≥80% stmts/lines, ≥70% branches |

### [`release.yml`](.github/workflows/release.yml) – Release & Deploy

Runs on **semver tags** (`v1.0.0`) or **manual dispatch** from the Actions UI.

| Stage | Tool | Notes |
|---|---|---|
| Docker Build & Push | Docker Hub | Tags `v1.0.0` and `latest` |
| Deploy to Kubernetes | Terraform | `terraform apply -auto-approve` |

#### Create a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Required GitHub Secrets

| Secret | Used by | Description |
|---|---|---|
| `DOCKERHUB_USERNAME` | release.yml | Docker Hub username |
| `DOCKERHUB_TOKEN` | release.yml | Docker Hub access token |
| `KUBE_CONFIG` | release.yml | `base64 -w0 ~/.kube/config` |
| `DB_USER` | release.yml | Passed as `TF_VAR_database_user` |
| `DB_PASSWORD` | release.yml | Passed as `TF_VAR_database_password` |

---

## IaC – Terraform

All Kubernetes resources are also managed as code using the [Terraform Kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest).

### Install Terraform

```bash
# Arch Linux
sudo pacman -S terraform

# Or via official installer
curl -fsSL https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip \
  | sudo busybox unzip -d /usr/local/bin -
```

### Deploy with Terraform (local / minikube)

```bash
# Copy and optionally edit vars
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

cd terraform/
terraform init
terraform plan -var="image_tag=latest"
terraform apply -auto-approve -var="image_tag=latest"
```

### Tear down

```bash
cd terraform/
terraform destroy -auto-approve
```

### Terraform Resources

| File | Resource |
|---|---|
| `namespace.tf` | `kubernetes_namespace` |
| `configmap.tf` | `kubernetes_config_map` |
| `secret.tf` | `kubernetes_secret` |
| `deployment.tf` | `kubernetes_deployment` |
| `service.tf` | `kubernetes_service` |
| `hpa.tf` | `kubernetes_horizontal_pod_autoscaler_v2` |
| `ingress.tf` | `kubernetes_ingress_v1` |

---

## Kubernetes Deployment

### Local (minikube)

```bash
# Start minikube with ingress
minikube start
minikube addons enable ingress

# Deploy everything
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml

# Verify pods (should show 2 Running)
kubectl get pods -n devsu-demo

# Check HPA
kubectl get hpa -n devsu-demo

# Access via port-forward
kubectl port-forward svc/devsu-demo-svc 8000:8000 -n devsu-demo
curl http://localhost:8000/api/users
```

### Kubernetes Resources

| Resource | Name | Detail |
|---|---|---|
| Namespace | `devsu-demo` | Isolated namespace |
| ConfigMap | `devsu-demo-config` | `DATABASE_NAME`, `PORT`, `NODE_ENV` |
| Secret | `devsu-demo-secret` | `DATABASE_USER`, `DATABASE_PASSWORD` |
| Deployment | `devsu-demo-deployment` | 2 replicas, non-root, liveness+readiness probes |
| HPA | `devsu-demo-hpa` | Min 2 / Max 5 pods, CPU 70% / Mem 80% |
| Service | `devsu-demo-svc` | ClusterIP on port 8000 |
| Ingress | `devsu-demo-ingress` | nginx, host `devsu-demo.local` |

---

## API Reference

### `GET /api/users`

Returns all users.

```json
[{ "id": 1, "dni": "12345678", "name": "Jane Doe" }]
```

### `GET /api/users/:id`

Returns a single user by ID. Returns `404` if not found.

### `POST /api/users`

Creates a new user.

**Body:**
```json
{ "dni": "12345678", "name": "Jane Doe" }
```

**Response (201):**
```json
{ "id": 1, "dni": "12345678", "name": "Jane Doe" }
```

---

## License

Copyright © 2023 Devsu. All rights reserved.
