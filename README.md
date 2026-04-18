# A1 Water Tech CI/CD Upgrade

This repository keeps the existing AWS production architecture intact and adds an external CI/CD and monitoring layer around it.

## Existing Runtime

- React storefront: `a1-water-online-shop`
- Flutter admin app: `a1_tech_billing`
- AWS backend: API Gateway + Lambda + RDS PostgreSQL + Cognito + S3 + Amplify
- Backend source: `aws-lambdas/products-api`

## Added DevOps Layer

- Dockerized React frontend with Nginx
- Dockerized Node.js container wrapper for the existing Lambda backend
- Jenkins pipeline for build, test, image push, and Kubernetes deployment
- Kubernetes manifests for frontend and backend
- Prometheus scraping for backend request count and response time

## CI/CD Architecture

```text
GitHub Push
   |
   v
GitHub Webhook
   |
   v
Jenkins Pipeline
   |
   +--> Build React frontend
   |
   +--> Install backend dependencies
   |
   +--> Run basic validation tests
   |
   +--> Build Docker images
   |
   +--> Push images to DockerHub
   |
   v
Kubernetes Cluster (Minikube or remote cluster)
   |
   +--> Frontend Deployment (Nginx, NodePort)
   |
   +--> Backend Deployment (Node.js API wrapper, ClusterIP)
   |
   v
Prometheus

AWS services remain active for business data and hosting integrations:
Amplify, API Gateway, Lambda, RDS PostgreSQL, Cognito, and S3
```

## Folder Structure

```text
A1 Water Tech/
|-- Jenkinsfile
|-- README.md
|-- k8s/
|   |-- backend-deployment.yaml
|   |-- backend-service.yaml
|   |-- frontend-deployment.yaml
|   `-- frontend-service.yaml
|-- prometheus.yml
|-- a1-water-online-shop/
|   |-- Dockerfile
|   `-- nginx.conf
`-- aws-lambdas/
    `-- products-api/
        |-- Dockerfile
        |-- metrics.mjs
        |-- server.mjs
        `-- package.json
```

## Jenkins Setup

1. Install Jenkins with Docker, Git, and Kubernetes tooling available on the agent.
2. Install Jenkins plugins:
   - Pipeline
   - Git
   - GitHub Integration
   - Credentials Binding
   - Docker Pipeline
3. Configure environment variables or credentials in Jenkins:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - `IMAGE_NAME`
4. Ensure the Jenkins agent can run:
   - `docker`
   - `kubectl`
   - `npm`
5. Point the Jenkins job at this repository and use the root `Jenkinsfile`.

## Docker Setup

1. Frontend image:
   - Build stage uses Node.js
   - Runtime uses Nginx
2. Backend image:
   - Uses Node.js Alpine
   - Runs the existing Lambda logic through a small HTTP adapter on port `3000`

Manual build commands:

```bash
docker build -t your-dockerhub-user/a1-water-tech-frontend:local ./a1-water-online-shop
docker build -t your-dockerhub-user/a1-water-tech-backend:local ./aws-lambdas/products-api
```

## Kubernetes Setup With Minikube

1. Start Minikube:

```bash
minikube start
```

2. Create backend secret for database connectivity used by the containerized backend:

```bash
kubectl create secret generic a1-backend-secrets \
  --from-literal=DB_HOST=your-rds-endpoint \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=postgres \
  --from-literal=DB_USER=your-db-user \
  --from-literal=DB_PASSWORD=your-db-password
```

3. Apply manifests:

```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

4. If deploying manually, update image references first:

```bash
kubectl set image deployment/a1-backend a1-backend=your-user/your-image-backend:tag
kubectl set image deployment/a1-frontend a1-frontend=your-user/your-image-frontend:tag
```

5. Access the frontend:

```bash
minikube service a1-frontend-service
```

## Prometheus Setup

1. Use the provided `prometheus.yml`.
2. Run Prometheus with the config mounted:

```bash
docker run --name prometheus \
  -p 9090:9090 \
  -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml" \
  prom/prometheus
```

3. The backend exposes:
   - `/health`
   - `/metrics`

Tracked metrics:

- `a1_backend_http_requests_total`
- `a1_backend_http_request_duration_seconds`

## GitHub Webhook To Jenkins

1. In Jenkins:
   - Open the pipeline job
   - Enable `GitHub hook trigger for GITScm polling`
2. In GitHub:
   - Open repository `Settings -> Webhooks -> Add webhook`
   - Payload URL:

```text
http://<your-jenkins-host>:8080/github-webhook/
```

3. Set content type to:

```text
application/json
```

4. Choose:
   - `Just the push event`
5. Save the webhook.

After that, every GitHub push triggers the Jenkins pipeline automatically.

## Pipeline Flow

The pipeline performs these stages:

1. Checkout from GitHub
2. Build frontend with `npm ci` and `npm run build`
3. Install backend dependencies with `npm ci`
4. Run placeholder validation tests
5. Build Docker images
6. Push Docker images to DockerHub
7. Deploy updated images to Kubernetes

## Commands To Run Pipeline Components Manually

Frontend build:

```bash
cd a1-water-online-shop
npm ci
npm run build
```

Backend install:

```bash
cd aws-lambdas/products-api
npm ci
```

Backend local container:

```bash
docker run -p 3000:3000 \
  -e DB_HOST=your-rds-endpoint \
  -e DB_PORT=5432 \
  -e DB_NAME=postgres \
  -e DB_USER=your-db-user \
  -e DB_PASSWORD=your-db-password \
  your-dockerhub-user/a1-water-tech-backend:local
```

Frontend local container:

```bash
docker run -p 8080:80 your-dockerhub-user/a1-water-tech-frontend:local
```

## Notes

- The AWS deployment path is not removed or replaced.
- The containerized backend is an operational wrapper around the same backend code for CI/CD and Kubernetes environments.
- The Flutter admin app remains part of the existing system and is intentionally left unchanged because this upgrade focuses on CI/CD for the current frontend and backend delivery flow.
