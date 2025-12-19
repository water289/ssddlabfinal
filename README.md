# Secure Online Voting System

This repository builds the Secure Online Voting System described in the course proposal. It delivers a FastAPI backend (authentication, elections, voting, audits) and a Vite/React frontend that consumes the secure APIs.

## Repository layout
- `src/backend/` — FastAPI app, SQLAlchemy models, Dockerfile, seeding scripts
- `src/frontend/` — Vite/React UI, Axios client, Dockerfile
- `docker/docker-compose.yml` — Local stack (PostgreSQL, backend, frontend)
- `docs/` — SRD, threat model, architecture notes, presentation plan
- `ci/`, `iac/`, `monitor/`, `reports/` — DevSecOps automation, IaC, monitoring, and reporting docs

## Run locally
### Backend
```bash
cd src/backend
python -m pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Set `SECRET_KEY` / `ADMIN_*` values via `.env` copied from `.env.example` for a production-grade deployment. Health and readiness endpoints are exposed at `/health` and `/ready`; Prometheus metrics are available at `/metrics`. Default rate limiting is enabled (per-minute window) and can be tuned via `RATE_LIMIT_PER_MINUTE` or disabled with `RATE_LIMIT_ENABLED=false`.

### Frontend
```bash
cd src/frontend
npm install
npm run dev
```

The frontend talks to `http://localhost:8000` by default and stores JWTs in `localStorage`. Use the login form and the seeded `admin` user (password from `.env`) for RBAC flows.

### Docker stack
```bash
cd docker
docker-compose up --build
```

The compose file starts PostgreSQL, the backend, and the production frontend. The `FRONTEND_ORIGINS` environment variable is prepopulated so the UI can only call the API from allowed origins.

## Testing & build
- Backend: run `pytest` from `src/backend` for the bundled smoke tests; `bandit -r src/backend` for quick static checks; `python -m compileall src/backend` for a lightweight build sanity check.
- Frontend: `npm run build` already executes during Docker builds; `npm run build` locally ensures Vite compilation passes.

## Kubernetes (local)
- Base manifests live in `docker/k8s/base` (backend, frontend, PostgreSQL, HPA, NetworkPolicy, ConfigMap, Secret).
- Apply locally with kustomize-friendly layout:
	```bash
	kubectl apply -k docker/k8s/base
	```
- Helm scaffold is under `docker/helm/voting-system`; install locally with:
	```bash
	helm install voting ./docker/helm/voting-system
	```
- Probes are wired to `/health` and `/ready`; Prometheus scrape annotations target `/metrics` on the backend.

## Security Enhancements
- At-rest encryption: votes are encrypted using AES-256 (AES-GCM). Provide `VOTE_ENCRYPTION_KEY` env var as base64 of 32 random bytes.
	```bash
	# Example key generation (Linux/macOS)
	openssl rand -base64 32
	```
- Optional TLS: set `SSL_CERTFILE` and `SSL_KEYFILE` env vars to enable HTTPS in the backend container (start script auto-detects).
- Kyverno policies: see `docker/k8s/policies` for non-root, no-privileged, and resource limits enforcement.
- IaC scaffolding: `iac/terraform/environments/dev` provides a starting point; GitHub Actions runs Checkov scans.