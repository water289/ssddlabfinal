# Architecture Documentation
**Secure Online Voting System**  
**Version:** 1.0  
**Date:** December 2024  
**Modeling Framework:** C4 Model (Context, Container, Component, Code)  
**Classification:** Internal

---

## 1. Executive Summary

This document provides comprehensive architectural documentation for the Secure Online Voting System, following the **C4 model** (Context, Containers, Components, Code) for visual representation and clarity. The system implements a cloud-native, security-first architecture deployed on AWS EC2 with Kubernetes orchestration.

**Architecture Principles:**
- **Security by Design:** Zero-trust networking, defense-in-depth, least privilege access
- **Cloud-Native:** Containerized workloads, declarative infrastructure (Terraform), immutable deployments
- **DevSecOps Automation:** 12+ security scans in CI/CD pipeline, policy-as-code enforcement
- **Observability:** Centralized logging (Loki), metrics (Prometheus/Grafana), runtime monitoring (Falco)
- **High Availability:** Kubernetes auto-scaling (HPA), PostgreSQL StatefulSet, health probes

---

## 2. C4 Level 1: System Context Diagram

### 2.1 System Context Overview

```
⚠️ DIAGRAM REQUIRED HERE - C4 Context Diagram
Title: "Secure Online Voting System - System Context"

External Actors (outside system boundary):
1. Voter (Person) - Submits votes, views election results - UNTRUSTED
2. Election Administrator (Person) - Creates elections, manages tallies - SEMI-TRUSTED
3. DevOps Engineer (Person) - Deploys infrastructure, monitors system - TRUSTED
4. Attacker (Person) - Adversarial actor attempting to compromise system - ADVERSARIAL

External Systems (outside system boundary):
5. GitHub (Software System) - Source code repository, CI/CD triggers
6. DockerHub (Software System) - Container image registry
7. AWS EC2 (Infrastructure) - Cloud infrastructure hosting

System Boundary (inside):
8. Secure Online Voting System (Software System) - Cloud-native voting platform with end-to-end security

Relationships (arrows):
- Voter → Voting System: "Submits votes, views results via HTTPS"
- Admin → Voting System: "Creates elections, views tallies via HTTPS"
- DevOps → Voting System: "Deploys updates, monitors health via kubectl"
- Voting System → GitHub: "Fetches code, triggers webhooks"
- Voting System → DockerHub: "Pulls container images"
- AWS EC2 → Voting System: "Hosts infrastructure (compute, storage, networking)"
- Attacker ⇢ Voting System: "Attempts unauthorized access (blocked by security controls)"

Tools: C4-PlantUML (https://github.com/plantuml-stdlib/C4-PlantUML), Structurizr, Lucidchart C4 template
Estimated time: 15 minutes
Example:
```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

Person(voter, "Voter", "Submits votes")
Person(admin, "Administrator", "Manages elections")
Person(devops, "DevOps Engineer", "Deploys system")
Person_Ext(attacker, "Attacker", "Adversarial actor")

System(voting, "Voting System", "Secure online voting platform")

System_Ext(github, "GitHub", "Source code repository")
System_Ext(dockerhub, "DockerHub", "Container registry")
System_Ext(aws, "AWS EC2", "Cloud infrastructure")

Rel(voter, voting, "Votes via HTTPS")
Rel(admin, voting, "Manages via HTTPS")
Rel(devops, voting, "Deploys via kubectl")
Rel(voting, github, "Pulls code")
Rel(voting, dockerhub, "Pulls images")
Rel(aws, voting, "Hosts")
Rel(attacker, voting, "Attacks (blocked)", "red")
@enduml
```
```

### 2.2 System Actors & Responsibilities

| Actor | Trust Level | Responsibilities | Authentication | Authorization |
|-------|-------------|-----------------|----------------|---------------|
| **Voter** | Untrusted | Register account, submit votes, view election results | Email + password (bcrypt hashed), JWT token (60 min expiry) | `voter` role (default) |
| **Election Administrator** | Semi-trusted | Create elections, add candidates, view tallies, manage election lifecycle | Email + password (bcrypt hashed), JWT token (60 min expiry) | `admin` role (manually assigned) |
| **DevOps Engineer** | Trusted | Deploy infrastructure (Terraform), configure Kubernetes, monitor logs/metrics, respond to incidents | SSH key (SSDD.pem), kubectl with RBAC certificate | Kubernetes `cluster-admin` (limited scope) |
| **Attacker** | Adversarial | Attempt credential theft, SQL injection, DDoS attacks, privilege escalation | N/A - Blocked by security controls | N/A - All unauthorized access denied |

### 2.3 External System Integrations

| External System | Purpose | Interface | Security |
|----------------|---------|-----------|----------|
| **GitHub** | Source code repository, CI/CD webhook triggers | HTTPS API, Git SSH | Branch protection rules, webhook secret validation |
| **DockerHub** | Container image registry for backend/frontend images | Docker Registry API v2 | Private repository, credentials in Jenkins |
| **AWS EC2** | Cloud infrastructure (compute: m7i.large, storage: 80GB EBS gp3, networking: VPC) | AWS CLI, Terraform provider | IAM removed (simplified), SSH key auth only |

---

## 3. C4 Level 2: Container Diagram

### 3.1 Container Architecture Overview

```
⚠️ DIAGRAM REQUIRED HERE - C4 Container Diagram
Title: "Secure Online Voting System - Containers"

Containers (inside system boundary):
1. Frontend SPA (React + Vite) [JavaScript/Node.js]
   - Description: Single-page application for voter/admin UI
   - Technology: React 18, Vite build tool, Axios HTTP client
   - Responsibilities: User authentication UI, vote submission form, election results display
   - Deployed as: Docker container (nginx:alpine serving static files)
   - Port: 80 (HTTP internally, proxied to HTTPS externally)

2. Backend API (FastAPI) [Python 3.11]
   - Description: RESTful API for authentication, voting, election management
   - Technology: FastAPI, SQLAlchemy ORM, Pydantic validation, JWT auth
   - Responsibilities: User auth (bcrypt), RBAC enforcement, vote processing, audit logging
   - Deployed as: Docker container (python:3.11-slim + uvicorn ASGI server)
   - Port: 8000 (HTTP internally, proxied to HTTPS externally)

3. PostgreSQL Database [PostgreSQL 15]
   - Description: Relational database for users, votes, elections
   - Technology: PostgreSQL 15 with AES-256 encryption (EBS)
   - Responsibilities: Persistent storage, ACID transactions, unique vote constraints
   - Deployed as: Kubernetes StatefulSet (persistent volume)
   - Port: 5432 (TLS-encrypted, internal network only)

4. Loki Logging Stack [Loki + Promtail]
   - Description: Centralized log aggregation and querying
   - Technology: Grafana Loki, Promtail log shipper
   - Responsibilities: Collect logs from all containers, retention (7 days), audit trail
   - Deployed as: Kubernetes Deployment (Helm chart)
   - Port: 3100 (HTTP, internal only)

5. Prometheus Monitoring [Prometheus + Grafana]
   - Description: Metrics collection and visualization
   - Technology: Prometheus (time-series DB), Grafana (dashboards)
   - Responsibilities: Scrape metrics (CPU, memory, HTTP requests), alerting
   - Deployed as: Kubernetes Deployment (Helm chart)
   - Port: 9090 (Prometheus), 3000 (Grafana - port-forwarded)

6. Falco Runtime Security [Falco]
   - Description: Runtime threat detection for containers
   - Technology: Falco with kernel module for syscall monitoring
   - Responsibilities: Detect suspicious behavior (privilege escalation, file tampering)
   - Deployed as: Kubernetes DaemonSet (runs on all nodes)
   - Port: N/A (kernel-level monitoring)

7. Kyverno Policy Engine [Kyverno]
   - Description: Kubernetes admission controller for policy enforcement
   - Technology: Kyverno (native K8s policy engine)
   - Responsibilities: Block privileged pods, enforce non-root users, require resource limits
   - Deployed as: Kubernetes Deployment (Helm chart)
   - Port: 9443 (admission webhook, HTTPS)

Relationships (arrows):
- Voter (Browser) → Frontend SPA: "HTTPS GET/POST requests (port 443 external)"
- Admin (Browser) → Frontend SPA: "HTTPS GET/POST requests (port 443 external)"
- Frontend SPA → Backend API: "HTTPS REST API (JWT in Authorization header)"
- Backend API → PostgreSQL: "SQL queries via SQLAlchemy ORM (TLS, port 5432)"
- Backend API → Jenkins Credentials: "Retrieve secrets (DB password, JWT key)"
- Backend API → Loki: "Logs via stdout (captured by Promtail)"
- Backend API → Prometheus: "Expose /metrics endpoint (scraped every 15s)"
- Prometheus → Alertmanager: "Send alerts (email/Slack - future)"
- Grafana → Prometheus: "Query metrics (PromQL)"
- Grafana → Loki: "Query logs (LogQL)"
- Falco → Loki: "Send security alerts"
- Kyverno → Kubernetes API: "Validate pod manifests (admission webhook)"

Tools: C4-PlantUML Container template, Lucidchart, or Draw.io
Estimated time: 25 minutes
```

### 3.2 Container Specifications

| Container | Image | Version | CPU Limit | Memory Limit | Storage | Replicas | Health Check |
|-----------|-------|---------|-----------|--------------|---------|----------|--------------|
| **Frontend** | `yourusername/voting-frontend:latest` | Latest | 200m | 256Mi | Ephemeral | 2 (HPA: 2-5) | HTTP GET `/` (200 OK) |
| **Backend** | `yourusername/voting-backend:latest` | Latest | 500m | 512Mi | Ephemeral | 2 (HPA: 2-10) | HTTP GET `/health` (200 OK) |
| **PostgreSQL** | `postgres:15-alpine` | 15.4 | 1000m | 1Gi | 10Gi PVC (gp3 EBS, encrypted) | 1 (StatefulSet) | PostgreSQL ready check |
| **Loki** | `grafana/loki:2.9.0` | 2.9.0 | 500m | 512Mi | 5Gi PVC | 1 | HTTP GET `/ready` |
| **Prometheus** | `prom/prometheus:v2.47.0` | 2.47.0 | 500m | 1Gi | 5Gi PVC | 1 | HTTP GET `/-/healthy` |
| **Grafana** | `grafana/grafana:10.1.0` | 10.1.0 | 200m | 256Mi | Ephemeral | 1 | HTTP GET `/api/health` |
| **Falco** | `falcosecurity/falco:0.36.0` | 0.36.0 | 200m | 512Mi | Ephemeral | 1 per node (DaemonSet) | Falco health endpoint |
| **Kyverno** | `ghcr.io/kyverno/kyverno:v1.10.0` | 1.10.0 | 500m | 512Mi | Ephemeral | 1 | Admission webhook health |

---

## 4. C4 Level 3: Component Diagram (Backend API)

### 4.1 Backend API Component Breakdown

```
⚠️ DIAGRAM REQUIRED HERE - C4 Component Diagram (Backend API Focus)
Title: "Backend API - Components"

Components (inside Backend API container):
1. Authentication Component [Python module: auth.py]
   - Description: Handles user login, JWT generation, password hashing
   - Responsibilities: bcrypt hashing, JWT creation/validation, role extraction
   - Dependencies: SQLAlchemy (User model), Passlib (bcrypt), PyJWT
   - Endpoints: POST /auth/register, POST /auth/token (login), GET /auth/me

2. Authorization Component [Python module: auth.py - require_role decorator]
   - Description: RBAC enforcement middleware
   - Responsibilities: Verify JWT signature, extract role claims, deny unauthorized access
   - Dependencies: PyJWT, FastAPI dependency injection
   - Used by: All protected endpoints (elections, votes, tally)

3. Voting Component [Python module: main.py - /votes endpoints]
   - Description: Vote submission and validation
   - Responsibilities: Check election status, prevent duplicate votes, store vote record
   - Dependencies: SQLAlchemy (Vote, Election models), Pydantic (VoteCreate schema)
   - Endpoints: POST /votes, GET /votes (admin only)

4. Election Management Component [Python module: main.py - /elections endpoints]
   - Description: Election CRUD operations (admin only)
   - Responsibilities: Create elections, add candidates, manage election lifecycle
   - Dependencies: SQLAlchemy (Election, Candidate models), RBAC (require_role)
   - Endpoints: POST /elections, GET /elections, GET /elections/{id}/tally

5. Database Component [Python module: database.py]
   - Description: Database connection pooling and ORM setup
   - Responsibilities: SQLAlchemy engine, session management, TLS connection
   - Dependencies: PostgreSQL database, environment variables (DB_HOST, DB_PASSWORD)
   - Used by: All components for data persistence

6. Validation Component [Python module: models.py]
   - Description: Request/response schema validation
   - Responsibilities: Pydantic models for type safety, input sanitization
   - Dependencies: Pydantic library
   - Used by: All endpoints for input validation

7. Logging Component [Python module: main.py - middleware]
   - Description: Request/response logging for audit trail
   - Responsibilities: Log all HTTP requests (method, path, user, timestamp)
   - Dependencies: FastAPI middleware, Python logging (stdout → Loki)
   - Used by: All endpoints (automatic via middleware)

8. Cryptography Component [Python module: crypto.py]
   - Description: Encryption/decryption for sensitive data (future enhancement)
   - Responsibilities: AES-256 encryption for vote data (future), key management
   - Dependencies: PyCryptodome library
   - Status: Placeholder for future blockchain-style vote hashing

Relationships (arrows):
- Frontend → Authentication Component: "POST /auth/register, POST /auth/token"
- Authentication Component → Database Component: "Query/Insert User table"
- Frontend → Voting Component: "POST /votes (with JWT)"
- Authorization Component → Voting Component: "Validate JWT, extract user_id"
- Voting Component → Database Component: "Insert Vote record, query Election status"
- Voting Component → Logging Component: "Log vote submission event"
- Frontend → Election Management Component: "POST /elections (admin JWT)"
- Authorization Component → Election Management Component: "Require admin role"
- Election Management Component → Database Component: "CRUD operations on Elections table"
- All Components → Validation Component: "Validate request payloads with Pydantic"

Tools: C4-PlantUML Component template, UML class diagram, or Lucidchart
Estimated time: 30 minutes
```

### 4.2 Backend API Endpoints

| Endpoint | Method | Auth Required | Role Required | Request Body | Response | Description |
|----------|--------|---------------|---------------|--------------|----------|-------------|
| `/auth/register` | POST | No | None | `{email, password, name}` | `{user_id, email, role}` | Create new user account |
| `/auth/token` | POST | No | None | `{email, password}` | `{access_token, token_type}` | Login and receive JWT |
| `/auth/me` | GET | Yes (JWT) | Any | N/A | `{user_id, email, role}` | Get current user info |
| `/votes` | POST | Yes (JWT) | `voter` or `admin` | `{election_id, candidate_id}` | `{vote_id, status}` | Submit vote |
| `/votes` | GET | Yes (JWT) | `admin` | N/A | `[{vote_id, voter_id, candidate_id}]` | View all votes (admin only) |
| `/elections` | POST | Yes (JWT) | `admin` | `{title, start_date, end_date}` | `{election_id, title}` | Create election |
| `/elections` | GET | No | None | N/A | `[{election_id, title, status}]` | List all elections |
| `/elections/{id}` | GET | No | None | N/A | `{election_id, title, candidates: [...]}` | Get election details |
| `/elections/{id}/tally` | GET | Yes (JWT) | `admin` | N/A | `{election_id, results: [{candidate, votes}]}` | Get vote tally (admin only) |
| `/health` | GET | No | None | N/A | `{status: "healthy"}` | Health check endpoint |

---

## 5. Data Flow Diagrams

### 5.1 Voter Registration & Login Flow

```
⚠️ DIAGRAM REQUIRED HERE - Sequence Diagram: "Voter Registration & Login"
Actors: Voter (Browser), Frontend SPA, Backend API, PostgreSQL Database

Flow:
1. Voter → Frontend: Click "Register" button
2. Frontend → Voter: Display registration form
3. Voter → Frontend: Enter email, password, name
4. Frontend → Backend: POST /auth/register {email, password, name} (HTTPS)
5. Backend → Backend: Validate input (Pydantic), hash password (bcrypt cost=12)
6. Backend → Database: INSERT INTO users (email, password_hash, name, role='voter')
7. Database → Backend: Return user_id
8. Backend → Frontend: Return 201 Created {user_id, email, role}
9. Frontend → Voter: Show "Registration successful" message

[Login Flow]
10. Voter → Frontend: Enter email, password on login form
11. Frontend → Backend: POST /auth/token {email, password} (HTTPS)
12. Backend → Database: SELECT * FROM users WHERE email = ? (parameterized query)
13. Database → Backend: Return user record with password_hash
14. Backend → Backend: Verify password using bcrypt.verify()
15. Backend → Backend: Generate JWT with claims {user_id, role, exp: 60 min}
16. Backend → Frontend: Return 200 OK {access_token, token_type: "Bearer"}
17. Frontend → Frontend: Store JWT in localStorage (note: not HttpOnly cookie)
18. Frontend → Voter: Redirect to dashboard

Tools: PlantUML sequence diagram, Lucidchart, or Draw.io
Estimated time: 15 minutes
```

### 5.2 Vote Submission Flow

```
⚠️ DIAGRAM REQUIRED HERE - Sequence Diagram: "Vote Submission"
Actors: Voter (Browser), Frontend SPA, Backend API, PostgreSQL Database, Loki (Logging)

Flow:
1. Voter → Frontend: Click "Submit Vote" button on election page
2. Frontend → Frontend: Read JWT from localStorage
3. Frontend → Backend: POST /votes {election_id, candidate_id} + Authorization: Bearer <JWT> (HTTPS)
4. Backend → Backend: Validate JWT signature using SECRET_KEY
5. Backend → Backend: Extract user_id from JWT claims
6. Backend → Database: SELECT * FROM elections WHERE id = ? AND status = 'active'
7. Database → Backend: Return election record (or 404 if not active)
8. Backend → Database: SELECT * FROM votes WHERE election_id = ? AND voter_id = ?
9. Database → Backend: Return existing vote (or empty if first-time)
10. Backend → Backend: If duplicate vote exists, return 400 Bad Request "Already voted"
11. Backend → Database: INSERT INTO votes (election_id, voter_id, candidate_id, timestamp)
12. Database → Backend: Return vote_id
13. Backend → Loki: Log event: {level: INFO, msg: "Vote submitted", user_id, election_id, candidate_id, timestamp}
14. Backend → Frontend: Return 201 Created {vote_id, status: "recorded"}
15. Frontend → Voter: Show "Vote successfully recorded" confirmation

Tools: PlantUML sequence diagram, Lucidchart, or Draw.io
Estimated time: 15 minutes
```

### 5.3 Admin Tally Flow

```
⚠️ DIAGRAM REQUIRED HERE - Sequence Diagram: "Admin View Tally"
Actors: Administrator (Browser), Frontend SPA, Backend API, PostgreSQL Database, Loki (Logging)

Flow:
1. Admin → Frontend: Click "View Tally" button for an election
2. Frontend → Frontend: Read JWT from localStorage (must have role='admin')
3. Frontend → Backend: GET /elections/{id}/tally + Authorization: Bearer <JWT> (HTTPS)
4. Backend → Backend: Validate JWT signature
5. Backend → Backend: Extract role from JWT claims
6. Backend → Backend: Require role='admin' (403 Forbidden if voter)
7. Backend → Database: SELECT candidate_id, COUNT(*) AS votes FROM votes WHERE election_id = ? GROUP BY candidate_id
8. Database → Backend: Return aggregated vote counts [{candidate_id: 1, votes: 150}, {candidate_id: 2, votes: 200}]
9. Backend → Database: SELECT * FROM candidates WHERE election_id = ? (get candidate names)
10. Database → Backend: Return candidate details
11. Backend → Backend: Merge vote counts with candidate names
12. Backend → Loki: Log event: {level: INFO, msg: "Tally accessed", admin_id, election_id, timestamp}
13. Backend → Frontend: Return 200 OK {election_id, results: [{candidate: "Alice", votes: 150}, {candidate: "Bob", votes: 200}]}
14. Frontend → Admin: Display tally results in bar chart

Tools: PlantUML sequence diagram, Lucidchart, or Draw.io
Estimated time: 15 minutes
```

---

## 6. Infrastructure Architecture

### 6.1 AWS EC2 Deployment Topology

```
⚠️ DIAGRAM REQUIRED HERE - Infrastructure Diagram
Title: "AWS EC2 + Kubernetes Deployment"

Components:
1. AWS Region: us-east-2 (Ohio)
2. VPC: Default VPC (CIDR: 172.31.0.0/16)
3. Availability Zone: us-east-2a (single AZ for lab project)
4. EC2 Instance: m7i.large (2 vCPU, 8GB RAM, Ubuntu 24.04 LTS)
   - Public IP: 3.144.186.47
   - Private IP: 172.31.X.X (dynamic)
   - Instance ID: i-XXXXXXXXXXXXX
5. Security Group: "voting-system-sg"
   - Ingress Rules:
     * SSH (port 22) from YOUR_IP/32 (restricted)
     * HTTP (port 80) from 0.0.0.0/0 (public)
     * HTTPS (port 443) from 0.0.0.0/0 (public)
     * Custom TCP (ports 30000-32767) from sg-self (Kubernetes NodePort)
   - Egress Rules: All traffic to 0.0.0.0/0
6. EBS Volume: 80GB gp3 (encrypted with AWS-managed key)
   - Device: /dev/sda1 (root volume)
   - Encryption: AES-256
7. Elastic IP: None (using dynamic public IP for lab)

Kubernetes Cluster (Minikube):
- Control Plane: Running on EC2 instance (single-node cluster)
- Namespaces: default (voting system), monitoring (Prometheus/Grafana/Loki), kyverno-system
- CNI Plugin: Calico (network policies enabled)
- Storage Class: standard (hostPath for local development)
- Persistent Volumes: PostgreSQL (10Gi), Loki (5Gi), Prometheus (5Gi)

Network Flow:
- Internet → AWS ALB (future) → EC2 Security Group → Kubernetes Ingress (future) → Frontend Service (NodePort 30080)
- Frontend Pod → Backend Service (ClusterIP port 8000) → Backend Pod
- Backend Pod → PostgreSQL Service (ClusterIP port 5432) → PostgreSQL StatefulSet Pod
- Backend Pod → Loki Service → Loki Pod
- Prometheus Pod → Backend Pod /metrics endpoint
- Grafana Pod → Prometheus Service → Prometheus Pod

Tools: AWS Architecture Icons (https://aws.amazon.com/architecture/icons/), Lucidchart AWS template, or Draw.io
Estimated time: 20 minutes
```

### 6.2 Network Policies

| Policy Name | Namespace | Target Pods | Ingress Rules | Egress Rules |
|-------------|-----------|-------------|---------------|--------------|
| **backend-network-policy** | default | `app=backend` | Allow from frontend pods (port 8000), Allow from monitoring (Prometheus scraping) | Allow to PostgreSQL (port 5432), Allow to Loki (port 3100), Allow to DNS (port 53) |
| **postgres-network-policy** | default | `app=postgres` | Allow from backend pods only (port 5432) | Deny all egress (database should not initiate connections) |
| **frontend-network-policy** | default | `app=frontend` | Allow from Internet (port 80) | Allow to backend (port 8000), Allow to DNS (port 53) |

---

## 7. Security Architecture

### 7.1 Defense-in-Depth Layers

```
⚠️ DIAGRAM REQUIRED HERE - Defense-in-Depth Diagram
Title: "Security Layers (Outside → Inside)"

Layer 1: Perimeter Security (Internet Boundary)
- AWS Security Group: Ingress filtering (SSH restricted to YOUR_IP, HTTP/HTTPS public)
- DDoS Protection: AWS Shield Standard (included), Rate limiting (future enhancement)

Layer 2: Network Security (Frontend → Backend)
- TLS 1.3: All data-in-transit encrypted (HTTPS)
- CORS: Restrict frontend origins to prevent cross-site attacks
- Kubernetes NetworkPolicy: Isolate backend from direct internet access

Layer 3: Application Security (Backend API)
- Authentication: JWT-based auth with bcrypt password hashing (cost factor 12)
- Authorization: RBAC enforcement via require_role decorator (admin vs voter)
- Input Validation: Pydantic schemas reject malformed requests
- SQL Injection Prevention: SQLAlchemy ORM with parameterized queries

Layer 4: Data Security (PostgreSQL Database)
- Encryption at Rest: AES-256 (AWS EBS encryption)
- Encryption in Transit: TLS connection between backend and database
- Access Control: Internal-only service (ClusterIP), no public exposure
- Unique Constraints: Prevent duplicate votes (one vote per voter per election)

Layer 5: Infrastructure Security (Kubernetes)
- Pod Security: Kyverno policies (non-root users, no privileged mode, resource limits)
- Container Security: Trivy scans for CVEs (zero critical/high vulnerabilities)
- Secret Management: Jenkins credentials (no hardcoded secrets in code)
- Network Isolation: NetworkPolicies restrict pod-to-pod communication

Layer 6: Runtime Security (Monitoring & Detection)
- Intrusion Detection: Falco monitors syscalls for suspicious behavior
- Log Monitoring: Loki aggregates audit logs (authentication, vote submissions, admin actions)
- Alerting: Prometheus alerts on high error rates, resource exhaustion (future: Alertmanager)

Layer 7: DevSecOps Security (CI/CD Pipeline)
- SAST: Bandit, Ruff, ESLint (static code analysis)
- SCA: Safety, NPM Audit (dependency vulnerability scanning)
- DAST: OWASP ZAP (dynamic API testing)
- IaC Scanning: Checkov (Terraform, Kubernetes manifests, Dockerfiles)
- Policy Enforcement: Kyverno admission controller blocks non-compliant deployments

Tools: PowerPoint layered diagram, Lucidchart, or Draw.io concentric circles
Estimated time: 15 minutes
```

### 7.2 Secrets Management Strategy

| Secret Type | Storage Location | Access Method | Rotation Policy |
|-------------|------------------|---------------|-----------------|
| **Database Password** | Jenkins credential ID: `postgres-password` | Injected as env var `POSTGRES_PASSWORD` in Jenkinsfile | Manual (every 90 days recommended) |
| **JWT Secret Key** | Jenkins credential ID: `secret-key` | Injected as env var `SECRET_KEY` in Jenkinsfile | Manual (every 180 days recommended) |
| **DockerHub Credentials** | Jenkins credential ID: `dockerhub-credentials` | Docker login in Jenkinsfile Stage 7 | Manual (on credential compromise) |
| **GitHub Webhook Secret** | Jenkins webhook configuration | Validates GitHub webhook payloads | Manual (on Jenkins reinstall) |
| **SSH Private Key (SSDD.pem)** | Local file `ssddlabfinal/SSDD.pem` (gitignored) | Used for EC2 SSH access | Never rotated (EC2 instance recreated if compromised) |

---

## 8. Deployment Architecture

### 8.1 Kubernetes Resource Hierarchy

```
Namespace: default
├── Deployments
│   ├── backend-deployment (2 replicas, HPA 2-10)
│   │   ├── Container: voting-backend (yourusername/voting-backend:latest)
│   │   │   ├── Env: POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD (from Jenkins)
│   │   │   ├── Env: SECRET_KEY (from Jenkins)
│   │   │   ├── Port: 8000 (HTTP)
│   │   │   ├── Liveness Probe: HTTP GET /health (every 10s)
│   │   │   ├── Readiness Probe: HTTP GET /health (initial delay 5s)
│   │   │   ├── Resources: CPU 500m, Memory 512Mi
│   │   │   └── SecurityContext: runAsNonRoot: true, runAsUser: 1000
│   └── frontend-deployment (2 replicas, HPA 2-5)
│       ├── Container: voting-frontend (yourusername/voting-frontend:latest)
│       │   ├── Port: 80 (HTTP)
│       │   ├── Liveness Probe: HTTP GET / (every 10s)
│       │   ├── Resources: CPU 200m, Memory 256Mi
│       │   └── SecurityContext: runAsNonRoot: true, runAsUser: 101 (nginx user)
├── StatefulSets
│   └── postgres-statefulset (1 replica, ordered deployment)
│       ├── Container: postgres (postgres:15-alpine)
│       │   ├── Env: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
│       │   ├── Port: 5432 (TCP)
│       │   ├── Volume: postgres-pvc (10Gi, ReadWriteOnce)
│       │   └── Resources: CPU 1000m, Memory 1Gi
├── Services
│   ├── backend-service (ClusterIP, port 8000 → targetPort 8000)
│   ├── frontend-service (NodePort, port 80 → targetPort 80, nodePort 30080)
│   └── postgres-service (ClusterIP, port 5432 → targetPort 5432)
├── HorizontalPodAutoscalers
│   ├── backend-hpa (target CPU 70%, min 2, max 10)
│   └── frontend-hpa (target CPU 70%, min 2, max 5) [Future enhancement]
├── NetworkPolicies
│   └── backend-network-policy (restrict ingress/egress)
└── ConfigMaps / Secrets (unused - secrets in Jenkins credentials)

Namespace: monitoring
├── Deployments
│   ├── loki-deployment (1 replica)
│   ├── prometheus-deployment (1 replica)
│   └── grafana-deployment (1 replica)
├── DaemonSets
│   └── promtail-daemonset (1 pod per node)
└── Services
    ├── loki-service (ClusterIP, port 3100)
    ├── prometheus-service (ClusterIP, port 9090)
    └── grafana-service (ClusterIP, port 3000)

Namespace: kyverno-system
├── Deployments
│   └── kyverno-deployment (1 replica)
└── ClusterPolicies
    ├── disallow-privileged (block privileged: true)
    ├── require-non-root (require runAsNonRoot: true)
    └── require-resource-limits (require CPU/memory limits)
```

### 8.2 Helm Chart Structure

```
docker/helm/voting-system/
├── Chart.yaml (metadata: name, version 1.0.0, appVersion 1.0)
├── values.yaml (configuration: replicas, image tags, resource limits)
└── templates/
    ├── _helpers.tpl (template functions: app name, labels)
    ├── backend-deployment.yaml (Backend Deployment + Service)
    ├── backend-hpa.yaml (HorizontalPodAutoscaler for backend)
    ├── backend-service.yaml (ClusterIP service)
    ├── frontend-deployment.yaml (Frontend Deployment + Service)
    ├── frontend-service.yaml (NodePort service)
    ├── postgres-statefulset.yaml (PostgreSQL StatefulSet + PVC)
    ├── postgres-service.yaml (ClusterIP service)
    └── networkpolicy.yaml (NetworkPolicy for backend)
```

---

## 9. Technology Stack

### 9.1 Technology Choices & Rationale

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| **Frontend Framework** | React | 18.2.0 | Component-based UI, large ecosystem, JSX for clarity |
| **Frontend Build Tool** | Vite | 4.4.0 | Fast development server, optimized production builds, ES modules support |
| **Frontend HTTP Client** | Axios | 1.5.0 | Promise-based, request/response interceptors for JWT injection |
| **Backend Framework** | FastAPI | 0.103.0 | High performance (async), automatic OpenAPI docs, Pydantic validation |
| **Backend Language** | Python | 3.11 | Rich security libraries (Passlib, PyJWT), readable syntax, fast development |
| **Web Server (Backend)** | Uvicorn | 0.23.0 | ASGI server for FastAPI, production-ready, async support |
| **Web Server (Frontend)** | Nginx | 1.25 (alpine) | Lightweight static file server, small Docker image (<50MB) |
| **Database** | PostgreSQL | 15-alpine | ACID compliance, JSON support, strong community, SQL standard |
| **ORM** | SQLAlchemy | 2.0.20 | Mature ORM, prevents SQL injection, database-agnostic migrations |
| **Validation** | Pydantic | 2.3.0 | Type safety, automatic data validation, JSON schema generation |
| **Authentication** | JWT (PyJWT) | 2.8.0 | Stateless auth, scalable, industry standard (RFC 7519) |
| **Password Hashing** | Bcrypt (Passlib) | 1.7.4 | Adaptive cost factor, salted hashing, resistant to brute-force |
| **Container Runtime** | Docker | 24.0.6 | Standard containerization, reproducible builds, OCI-compliant |
| **Orchestration** | Kubernetes (Minikube) | 1.31.0 | Production-like environment, auto-scaling, self-healing, declarative config |
| **Policy Engine** | Kyverno | 1.10.0 | Kubernetes-native, easier than OPA for basic policies, YAML-based |
| **Infrastructure as Code** | Terraform | 1.5.0 | Declarative IaC, AWS provider, state management, reusable modules |
| **CI/CD** | Jenkins | 2.426.0 | Self-hosted, extensive plugin ecosystem, Jenkinsfile pipeline-as-code |
| **Logging** | Loki + Promtail | 2.9.0 | Cost-effective (indexes labels not logs), integrates with Grafana |
| **Metrics** | Prometheus | 2.47.0 | Time-series DB, pull-based model, powerful PromQL query language |
| **Visualization** | Grafana | 10.1.0 | Unified dashboards (logs + metrics), alerting, templating |
| **Runtime Security** | Falco | 0.36.0 | Kernel-level threat detection, Cloud Native Computing Foundation project |

---

## 10. Scalability & Performance

### 10.1 Horizontal Scaling Strategy

| Component | Scaling Method | Trigger | Min Replicas | Max Replicas | Target Metric |
|-----------|---------------|---------|--------------|--------------|---------------|
| **Backend API** | Kubernetes HPA | CPU > 70% for 2 minutes | 2 | 10 | CPU utilization |
| **Frontend** | Manual scaling (future: HPA) | N/A | 2 | 5 | CPU utilization (future) |
| **PostgreSQL** | Vertical scaling (future: read replicas) | N/A | 1 | 1 | Manual intervention |
| **Prometheus** | Vertical scaling | Disk usage > 80% | 1 | 1 | Storage expansion |

### 10.2 Performance Benchmarks (Expected)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **API Response Time (p95)** | < 200ms | Prometheus histogram `http_request_duration_seconds{quantile="0.95"}` |
| **Vote Submission Latency** | < 500ms | End-to-end test (frontend → backend → database) |
| **Concurrent Users (sustained)** | 100 users | Load testing with k6 or Locust (future) |
| **Database Query Time (p95)** | < 50ms | PostgreSQL slow query log |
| **Frontend Page Load Time** | < 2 seconds | Lighthouse performance score (target: 90+) |

---

## 11. Disaster Recovery & Business Continuity

### 11.1 Backup Strategy

| Component | Backup Method | Frequency | Retention | Recovery Time Objective (RTO) |
|-----------|---------------|-----------|-----------|-------------------------------|
| **PostgreSQL Data** | StatefulSet PersistentVolume (AWS EBS snapshots - future) | Daily (manual) | 7 days | < 1 hour |
| **Kubernetes Manifests** | Git repository (version controlled) | Every commit | Indefinite | < 10 minutes |
| **Helm Charts** | Git repository (version controlled) | Every commit | Indefinite | < 10 minutes |
| **Terraform State** | Local backend (future: S3 with versioning) | Every apply | 30 days (future) | < 30 minutes |
| **Audit Logs (Loki)** | Persistent volume (no external backup) | N/A | 7 days | Non-recoverable (acceptable for lab) |

### 11.2 Rollback Procedures

| Scenario | Rollback Method | Command | Time to Rollback |
|----------|----------------|---------|------------------|
| **Bad Backend Deployment** | Helm rollback | `helm rollback voting-system 1 -n default` | < 2 minutes |
| **Database Schema Migration Failure** | Manual SQL rollback script | `psql -h postgres-service -U postgres -d voting_db -f rollback.sql` | < 10 minutes |
| **Infrastructure Change (Terraform)** | Revert Git commit + terraform apply | `git revert <commit> && terraform apply` | < 15 minutes |
| **Compromised Secrets** | Rotate secrets in Jenkins + redeploy | Update Jenkins credentials → trigger pipeline | < 30 minutes |

---

## 12. Future Architecture Enhancements

### 12.1 Planned Improvements (Post-Lab)

| Enhancement | Description | Priority | Effort | Business Value |
|-------------|-------------|----------|--------|----------------|
| **Multi-Region Deployment** | Deploy to multiple AWS regions for disaster recovery | **LOW** | 4-6 weeks | High availability (99.99% SLA) |
| **Read Replicas (PostgreSQL)** | Add read-only database replicas for tally queries | **MEDIUM** | 2 weeks | Improved performance for reporting |
| **API Rate Limiting** | Implement per-IP rate limiting (100 req/min) | **HIGH** | 1 week | DDoS protection |
| **CDN for Frontend** | Use CloudFront for static asset delivery | **MEDIUM** | 1 week | Reduced latency for global users |
| **Blockchain Vote Verification** | Add cryptographic vote hashing for tamper evidence | **LOW** | 6+ weeks | Enhanced election integrity |
| **External SIEM Integration** | Forward logs to Splunk/ELK for advanced correlation | **MEDIUM** | 2-3 weeks | Improved threat detection |
| **Kubernetes Ingress Controller** | Replace NodePort with Nginx Ingress + TLS | **MEDIUM** | 1 week | Production-ready networking |

---

## 13. References

1. **C4 Model Documentation:** https://c4model.com/ (Context, Container, Component, Code diagrams)
2. **Kubernetes Architecture:** https://kubernetes.io/docs/concepts/architecture/
3. **FastAPI Documentation:** https://fastapi.tiangolo.com/
4. **PostgreSQL Documentation:** https://www.postgresql.org/docs/15/index.html
5. **AWS EC2 Best Practices:** https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html
6. **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
7. **Helm Chart Best Practices:** https://helm.sh/docs/chart_best_practices/
8. **Project Requirements:** `ssddlabfinal/project.md` (CYC386 Lab Brief)

---

**Document Status:** ✅ FINAL (Version 1.0)  
**Next Review:** Post-deployment architecture audit (Week 15)  
**Approval Required:** Instructor sign-off for final defense
- CI ⇄ Infra: GitHub Actions uses OIDC to deploy via Terraform Cloud (or `aws` provider) with least privilege roles.

## Security Control Mapping
| Control | OWASP ASVS | NIST CSF |
| --- | --- | --- |
| JWT auth + RBAC middleware | 2.1, 2.4 | Identify/Protect |
| IaC (Terraform) with policy as code | 15.4, 15.7 | Protect/Respond |
| Prometheus metrics + Grafana dashboards | 12.1, 12.2 | Detect/Respond |
| Falco runtime detection on pods | 12.4, 15.8 | Detect/Respond |
| GitHub Actions + ZAP/Trivy | 5.3, 2.5 | Identify/Protect |

## Deployment Targets
- Containerized backend & frontend built via Dockerfiles in `src/backend` and `src/frontend`.
- Docker Compose used for local development (`docker/docker-compose.yml`).
- Production deploys to Kubernetes (Helm templates located in `/docker/helm` stubbed for later completion).

## Observability Data Flow
Prometheus scrapes FastAPI `/metrics` endpoint (via `prometheus.flask`). Loki collects FastAPI logs with structured JSON; Falco sidecar listens for suspicious syscalls; Alertmanager sends notifications when Liveness/Readiness fail.
