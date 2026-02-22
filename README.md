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
git clone https://github.com/<your-username>/devsu-demo-devops-nodejs.git
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

The pipeline is defined in [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) and runs on every push and PR to `main`.

| Stage | Tool | Trigger |
|---|---|---|
| Code Build | `npm ci` | Every push / PR |
| Static Analysis | ESLint | Every push / PR |
| Unit Tests | Jest | Every push / PR |
| Code Coverage | Jest `--coverage` (≥80%) | Every push / PR |
| Docker Build & Push | Docker Hub | Push to `main` only |
| Deploy to Kubernetes | `kubectl apply` | Push to `main` only |

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `KUBE_CONFIG` | base64-encoded kubeconfig for target cluster |

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
