# Secure Online Voting System - Operations Guide

## Local Development

### Prerequisites
- Python 3.11+
- Node.js 20+
- Docker & Docker Compose
- kubectl (for Kubernetes deployment)
- Helm 3+ (for chart deployment)
- kind or minikube (for local Kubernetes cluster)

### Backend Local Run
```bash
cd ssddlabfinal/src/backend
python -m pip install -r requirements.txt
export DATABASE_URL="sqlite:///./dev.db"
export SECRET_KEY="dev-secret-change-in-production"
export VOTE_ENCRYPTION_KEY=$(openssl rand -base64 32)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Access:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Ready: http://localhost:8000/ready
- Metrics: http://localhost:8000/metrics

### Frontend Local Run
```bash
cd ssddlabfinal/src/frontend
npm install
npm run dev
```

Access: http://localhost:5173

### Docker Compose Stack
```bash
cd ssddlabfinal/docker
docker-compose up --build
```

Services:
- Backend: http://localhost:8000
- Frontend: http://localhost:5173
- PostgreSQL: localhost:5432

## Kubernetes Deployment (Local)

### Create Local Cluster
```bash
# Using kind
kind create cluster --name voting-local

# Using minikube
minikube start --cpus=4 --memory=8192
```

### Generate Encryption Key
```bash
# Linux/macOS
export VOTE_ENC_KEY=$(openssl rand -base64 32)
echo $VOTE_ENC_KEY

# Windows PowerShell
$VOTE_ENC_KEY = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
Write-Output $VOTE_ENC_KEY
```

### Update Secrets
Edit `ssddlabfinal/docker/k8s/base/secret.yaml` and replace:
- `vote_encryption_key` with base64 of your generated key
- `secret_key` with base64 of JWT secret
- `postgres_password` with base64 of DB password

### Deploy with Kustomize
```bash
cd ssddlabfinal
kubectl apply -k docker/k8s/base
kubectl get pods -n default
kubectl port-forward svc/voting-backend 8000:8000
kubectl port-forward svc/voting-frontend 5173:80
```

### Deploy with Helm
```bash
cd ssddlabfinal
helm install voting ./docker/helm/voting-system \
  --set global.secretKey=your-jwt-secret \
  --set global.database.password=your-db-password \
  --set global.voteEncryptionKey=$(openssl rand -base64 32)

kubectl get pods
helm status voting
```

### Install Kyverno Policies
```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.0/install.yaml
kubectl apply -f docker/k8s/policies/require-non-root.yaml
kubectl apply -f docker/k8s/policies/disallow-privileged.yaml
kubectl apply -f docker/k8s/policies/require-resource-limits.yaml
```

### Install OPA Gatekeeper
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
kubectl apply -f docker/k8s/policies/gatekeeper/templates/
kubectl apply -f docker/k8s/policies/gatekeeper/constraints/
```

## Monitoring Stack

### Install Prometheus/Grafana
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitor/prometheus/values.yaml
```

### Access Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Username: admin
# Password: (retrieve with below command)
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

### Install Loki
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack -n monitoring -f monitor/loki/values.yaml
```

### Install Falco
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n monitoring -f monitor/falco/values.yaml
```

## CI/CD

### GitHub Actions
Workflows automatically run on push/PR:
- Backend CI: lint, bandit, pytest, build, Trivy scan
- Frontend CI: build, Trivy scan
- Security Scans: OWASP ZAP DAST
- IaC Checkov: Terraform validation
- SonarQube: SAST analysis (requires SONAR_TOKEN secret)

### Jenkins Pipeline
Configure Jenkins credentials:
- `dockerhub-creds`: DockerHub username/password
- `secure-voting-secret-key`: JWT secret key
- `secure-voting-postgres-password`: Database password

Run with parameters:
- `DEPLOY_TO_K8S=true`: Deploy to Kubernetes after build
- `INSTALL_MONITORING=true`: Install Prometheus/Grafana stack

## Testing

### Backend Tests
```bash
cd ssddlabfinal/src/backend
pip install pytest
pytest -v
```

### Security Scans
```bash
# Bandit SAST
bandit -r src/backend -x __pycache__,tests

# Trivy container scan
docker build -t secure-voting-backend:test src/backend
trivy image secure-voting-backend:test

# OWASP ZAP
docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:8000 -r zap_report.html
```

### IaC Validation
```bash
# Checkov
pip install checkov
checkov -d iac/terraform --quiet

# Terraform validate
cd iac/terraform/environments/dev
terraform init
terraform validate
```

## Troubleshooting

### Backend won't start
- Check `VOTE_ENCRYPTION_KEY` is set and valid base64
- Verify database connection string in `DATABASE_URL`
- Check logs: `kubectl logs -l app=secure-voting,component=backend`

### Rate limiting issues
- Adjust `RATE_LIMIT_PER_MINUTE` env var
- Disable with `RATE_LIMIT_ENABLED=false`

### Encryption errors
- Ensure key is exactly 32 bytes (256 bits) when decoded from base64
- Regenerate: `openssl rand -base64 32`

### Policy violations
- Check Kyverno/Gatekeeper logs
- Ensure deployments have `securityContext.runAsNonRoot: true`
- Set resource limits on all containers
