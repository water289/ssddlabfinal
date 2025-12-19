# Threat Model Analysis
**Secure Online Voting System**  
**Version:** 1.0  
**Date:** December 2024  
**Methodology:** STRIDE + DREAD  
**Classification:** Internal

---

## 1. Executive Summary

This threat model identifies, analyzes, and prioritizes security threats to the Secure Online Voting System using the **STRIDE** methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) combined with **DREAD** risk scoring (Damage, Reproducibility, Exploitability, Affected Users, Discoverability).

**Key Findings:**
- **Critical Threats:** 3 high-risk threats identified (vote tampering, credential theft, database compromise)
- **Attack Surface:** 7 trust boundaries analyzed (Internet → Frontend → Backend → Database → Secrets → Kubernetes → Monitoring)
- **Mitigations:** 15 security controls implemented (see SRD requirements SR-01 to SR-15)
- **Residual Risk:** MEDIUM - Acceptable for lab environment; MFA and rate limiting recommended for production

---

## 2. System Context & Trust Boundaries

### 2.1 System Context Diagram

```
⚠️ DIAGRAM REQUIRED HERE - C4 Context Diagram
Expected content:
- External actors: Voters (untrusted), Election Admins (semi-trusted), DevOps Team (trusted), Attackers (adversarial)
- System boundary: Secure Online Voting System (cloud-hosted)
- External systems: GitHub (code repository), DockerHub (container registry), AWS EC2 (infrastructure)
- Interactions: 
  * Voters → Frontend (HTTPS, public internet)
  * Admins → Frontend (HTTPS, authenticated)
  * Frontend → Backend API (JWT-authenticated REST)
  * Backend → PostgreSQL (TLS, password auth, internal network)
  * Backend → Jenkins Credentials (secret retrieval)
  * DevOps → Kubernetes (kubectl, authenticated)
  * Monitoring Stack → Alertmanager (internal, authenticated)
Tools: Lucidchart, Draw.io, or C4-PlantUML
Estimated time: 15 minutes
```

### 2.2 Trust Boundary Identification

| Boundary ID | From Zone | To Zone | Trust Level | Protection Mechanism | Attack Surface |
|-------------|-----------|---------|-------------|---------------------|----------------|
| **TB-01** | Internet (Untrusted) | Frontend (DMZ) | **ZERO TRUST** | HTTPS/TLS 1.3, CORS policies | **HIGH** - Public access |
| **TB-02** | Frontend (DMZ) | Backend API (App Tier) | **AUTHENTICATED** | JWT validation, RBAC | **MEDIUM** - Requires valid token |
| **TB-03** | Backend API (App Tier) | PostgreSQL (Data Tier) | **ENCRYPTED** | TLS connection, password auth, internal network | **LOW** - Internal only |
| **TB-04** | Backend API (App Tier) | Jenkins Credentials (Secrets) | **PRIVILEGED** | Jenkins credential binding, encrypted storage | **LOW** - CI/CD only |
| **TB-05** | Kubernetes Pods (Runtime) | OPA/Kyverno (Policy Engine) | **ENFORCED** | Admission webhooks, policy violations block deployment | **LOW** - Infrastructure control |
| **TB-06** | Monitoring Stack (Observability) | Alertmanager (Notifications) | **INTERNAL** | Internal network, authenticated Grafana access | **LOW** - Ops team only |
| **TB-07** | DevOps Team (Admin) | Kubernetes API (Control Plane) | **PRIVILEGED** | RBAC, kubeconfig certificates | **MEDIUM** - Admin access risk |

### 2.3 Data Flow Diagram

```
⚠️ DIAGRAM REQUIRED HERE - Data Flow Diagram (DFD Level 1)
Expected content:
- External Entity 1: Voter (untrusted)
- Process 1: Frontend UI (React SPA)
- Process 2: Backend API (FastAPI)
- Process 3: Authentication Service (JWT issuer)
- Data Store 1: PostgreSQL Database (encrypted)
- Data Store 2: Audit Logs (Loki)
- Data Store 3: Jenkins Credentials (secrets)
- Data flows:
  * Voter → Frontend: Login credentials (HTTPS)
  * Frontend → Backend: JWT token + API requests (HTTPS)
  * Backend → Database: SQL queries (TLS, parameterized)
  * Backend → Audit Logs: Security events (stdout → Loki)
  * Backend → Secrets: Retrieve DB password (Jenkins API)
- Trust boundaries marked at each zone transition
Tools: Microsoft Threat Modeling Tool, Lucidchart DFD template, or Draw.io
Estimated time: 20 minutes
```

---

## 3. STRIDE Threat Analysis

### 3.1 Threat Enumeration by Category

#### 3.1.1 Spoofing Threats (S)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **S-01** | Attacker spoofs voter identity using stolen credentials | Backend API (`/login` endpoint) | Phishing email → credential theft → login with valid email/password | **D:4, R:3, E:3, A:4, D:4 = 18/25 (HIGH)** | SR-01 (bcrypt), SR-02 (generic errors), SR-11 (login logging) | **MEDIUM** - MFA not implemented |
| **S-02** | Attacker forges JWT token with admin role claims | Backend API (JWT validation in `auth.py`) | Brute-force JWT secret key → craft token with `{"role": "admin"}` | **D:5, R:2, E:2, A:5, D:3 = 17/25 (MEDIUM)** | SR-05 (JWT signature validation), SR-07 (secret key in Jenkins, not hardcoded) | **LOW** - Strong secret key required |
| **S-03** | Session hijacking via XSS attack stealing JWT from localStorage | Frontend (React app) | Inject malicious script → steal token from localStorage → replay in API requests | **D:4, R:3, E:3, A:4, D:4 = 18/25 (HIGH)** | SR-09 (input validation), CORS policy, HttpOnly cookies (future enhancement) | **MEDIUM** - localStorage used (not HttpOnly cookies) |

**DREAD Legend:** D=Damage, R=Reproducibility, E=Exploitability, A=Affected Users, D=Discoverability (scale 1-5)

#### 3.1.2 Tampering Threats (T)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **T-01** | Attacker modifies vote records directly in database | PostgreSQL database | SQL injection via `/votes` endpoint → `UPDATE votes SET candidate_id = X` | **D:5, R:2, E:2, A:5, D:3 = 17/25 (MEDIUM)** | SR-10 (parameterized queries), SR-09 (input validation), SR-15 (OWASP ZAP testing) | **VERY LOW** - SQLAlchemy ORM prevents SQLi |
| **T-02** | Attacker tampers with election configuration (dates, candidates) | Backend API (`/elections` endpoint) | Gain admin access (via S-02) → modify election JSON payload | **D:5, R:3, E:3, A:5, D:4 = 20/25 (HIGH)** | SR-04 (RBAC enforcement), SR-12 (audit logging), SR-05 (JWT validation) | **LOW** - Requires admin role compromise |
| **T-03** | Attacker modifies Docker images in DockerHub repository | DockerHub registry | Compromise DockerHub credentials → push malicious image with backdoor | **D:5, R:2, E:2, A:5, D:2 = 16/25 (MEDIUM)** | SR-14 (Trivy image scanning), SR-07 (credentials in Jenkins, not GitHub), image signing (future enhancement) | **MEDIUM** - No image signing implemented |
| **T-04** | Attacker tampers with Kubernetes manifests before deployment | GitHub repository | Compromise GitHub account → modify `backend-deployment.yaml` to add privileged mode | **D:4, R:2, E:3, A:5, D:3 = 17/25 (MEDIUM)** | SR-13 (Kyverno policy blocks privileged pods), SR-15 (Checkov IaC scanning), branch protection rules | **LOW** - Policy enforcement blocks deployment |

#### 3.1.3 Repudiation Threats (R)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **R-01** | Voter denies casting vote ("I didn't vote for that candidate") | Audit logs (Loki) | Submit vote → claim system error or attack | **D:3, R:5, E:5, A:3, D:5 = 21/25 (HIGH)** | SR-12 (immutable audit logs), SR-11 (timestamped authentication), cryptographic vote hashing (future) | **LOW** - Audit trail proves vote submission |
| **R-02** | Admin denies modifying election results | Audit logs (Loki) | Access `/elections/{id}/tally` → modify results → claim system glitch | **D:5, R:3, E:4, A:5, D:4 = 21/25 (HIGH)** | SR-12 (audit logs capture all admin actions), SR-04 (RBAC limits admin access), Loki retention policy | **LOW** - All admin API calls logged with JWT claims |
| **R-03** | Attacker deletes audit logs to hide attack | Loki storage (Kubernetes PVC) | Gain Kubernetes admin access → delete Loki pods/PVCs | **D:4, R:2, E:2, A:5, D:3 = 16/25 (MEDIUM)** | SR-13 (non-root containers), Kubernetes RBAC, log forwarding to external SIEM (future) | **MEDIUM** - No external log backup |

#### 3.1.4 Information Disclosure Threats (I)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **I-01** | Attacker extracts voter credentials from database dump | PostgreSQL database | Exploit backup misconfiguration → download unencrypted backup file | **D:5, R:2, E:2, A:5, D:3 = 17/25 (MEDIUM)** | SR-08 (encrypted EBS volume), SR-01 (bcrypt hashing prevents plaintext recovery), access controls on backups | **LOW** - Bcrypt makes password cracking infeasible |
| **I-02** | Attacker intercepts JWT tokens via man-in-the-middle attack | Network traffic (Frontend ↔ Backend) | ARP spoofing on local network → capture HTTP traffic | **D:4, R:2, E:2, A:3, D:3 = 14/25 (MEDIUM)** | SR-06 (TLS 1.3 enforced), certificate pinning (future enhancement) | **VERY LOW** - TLS prevents MITM |
| **I-03** | Attacker accesses hardcoded secrets in GitHub repository | GitHub repository (`.env` file committed by mistake) | Search GitHub for exposed secrets → extract DB password | **D:5, R:5, E:5, A:5, D:5 = 25/25 (CRITICAL)** | SR-07 (secrets in Jenkins, `.env` gitignored), SR-15 (Bandit/Ruff detect hardcoded secrets), GitHub secret scanning | **VERY LOW** - `.env` never committed |
| **I-04** | Attacker enumerates valid user emails via timing attack | Backend API (`/login` endpoint) | Measure response time difference: valid email (slow bcrypt) vs invalid email (fast) | **D:2, R:4, E:4, A:3, D:4 = 17/25 (MEDIUM)** | SR-02 (generic error messages), constant-time comparison (future enhancement) | **MEDIUM** - Timing attack still possible |

#### 3.1.5 Denial of Service Threats (D)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **D-01** | Attacker floods `/votes` endpoint with spam requests | Backend API (vote submission) | Automated script sends 10,000 requests/sec → exhaust server resources | **D:4, R:5, E:5, A:5, D:5 = 24/25 (CRITICAL)** | Kubernetes HPA (auto-scaling), rate limiting (future enhancement), AWS ALB throttling (future) | **HIGH** - No rate limiting implemented |
| **D-02** | Attacker crashes PostgreSQL with resource-intensive queries | PostgreSQL database | Craft query with massive JOIN → consume CPU/memory → database unresponsive | **D:4, R:3, E:3, A:5, D:4 = 19/25 (HIGH)** | SR-09 (input validation limits query complexity), database resource limits in K8s, query timeout settings | **MEDIUM** - Resource limits configured |
| **D-03** | Attacker fills disk space with excessive log entries | Loki storage (Kubernetes PVC) | Generate millions of error logs → fill PVC → monitoring fails | **D:3, R:3, E:4, A:3, D:4 = 17/25 (MEDIUM)** | Loki retention policy (7 days), log rate limiting, PVC size monitoring in Grafana | **LOW** - Retention policy prevents unbounded growth |
| **D-04** | Attacker triggers pod restart loop via policy violations | Kubernetes pods (backend/frontend) | Deploy malformed manifest → Kyverno blocks → redeploy loop → API unavailable | **D:3, R:2, E:2, A:4, D:3 = 14/25 (MEDIUM)** | SR-13 (policy validation in CI/CD), SR-15 (Checkov prevents misconfigurations), manual deployment approval | **LOW** - Pipeline catches errors before deployment |

#### 3.1.6 Elevation of Privilege Threats (E)

| Threat ID | Threat Description | Affected Component | Attack Vector | DREAD Score | Mitigation (SRD Req) | Residual Risk |
|-----------|-------------------|-------------------|---------------|-------------|---------------------|---------------|
| **E-01** | Attacker escalates from voter to admin role | Backend API (RBAC enforcement) | Exploit JWT claim injection vulnerability → modify `{"role": "voter"}` to `{"role": "admin"}` | **D:5, R:2, E:2, A:5, D:3 = 17/25 (MEDIUM)** | SR-05 (JWT signature prevents tampering), SR-04 (role checks in every endpoint), SR-15 (SAST detects RBAC bugs) | **VERY LOW** - JWT signature cryptographically secured |
| **E-02** | Attacker escapes container to access Kubernetes node | Backend container | Exploit kernel vulnerability → break out of container → access host filesystem | **D:5, R:1, E:1, A:5, D:2 = 14/25 (MEDIUM)** | SR-13 (non-root user, no privileged mode), SR-14 (Trivy scans for container CVEs), Falco runtime monitoring | **LOW** - Multiple defense layers |
| **E-03** | Attacker gains Kubernetes cluster-admin access | Kubernetes RBAC | Exploit misconfigured ServiceAccount → access cluster-admin role | **D:5, R:2, E:2, A:5, D:3 = 17/25 (MEDIUM)** | Kubernetes RBAC least privilege, SR-13 (Kyverno enforces RBAC policies), no default ServiceAccount tokens | **LOW** - RBAC properly configured |
| **E-04** | Attacker pivots from compromised Jenkins to Kubernetes | Jenkins server | Compromise Jenkins credentials → use stored kubeconfig → deploy malicious pods | **D:5, R:3, E:3, A:5, D:4 = 20/25 (HIGH)** | Jenkins credential encryption, kubeconfig with limited RBAC, Jenkins security hardening (authentication required) | **MEDIUM** - Jenkins is high-value target |

---

## 4. Attack Tree Analysis

### 4.1 High-Priority Attack Tree: "Manipulate Election Results"

```
⚠️ DIAGRAM REQUIRED HERE - Attack Tree Diagram
Root Goal: Manipulate election results (change vote tallies)
├── OR
│   ├── AND [Path 1: Direct Database Tampering]
│   │   ├── Exploit SQL injection vulnerability (T-01) [MITIGATED by SR-10]
│   │   └── Bypass input validation (T-01) [MITIGATED by SR-09]
│   │
│   ├── AND [Path 2: Admin Privilege Escalation]
│   │   ├── Steal admin JWT token (S-02) [MITIGATED by SR-05]
│   │   └── Access /elections/{id}/tally endpoint (T-02) [MITIGATED by SR-04]
│   │
│   ├── AND [Path 3: Container Image Backdoor]
│   │   ├── Compromise DockerHub credentials (T-03) [MITIGATED by SR-07]
│   │   ├── Push malicious backend image (T-03) [MITIGATED by SR-14]
│   │   └── Trigger deployment (requires Jenkins access) [MITIGATED by Jenkins auth]
│   │
│   └── AND [Path 4: Kubernetes Manifest Tampering]
│       ├── Compromise GitHub repository (T-04) [MITIGATED by branch protection]
│       ├── Modify backend-deployment.yaml (T-04) [MITIGATED by SR-15 Checkov]
│       └── Bypass Kyverno policy enforcement (T-04) [MITIGATED by SR-13]

Tools: Microsoft Threat Modeling Tool, Attack Tree diagram template, or Draw.io
Format: Hierarchical tree with AND/OR logic gates, probability/impact scores at each node
Estimated time: 20 minutes
```

**Attack Path Risk Assessment:**
- **Path 1 (SQL Injection):** VERY LOW risk - SQLAlchemy ORM prevents injection
- **Path 2 (Privilege Escalation):** LOW risk - JWT signature cryptographically secured
- **Path 3 (Image Backdoor):** MEDIUM risk - Requires credential compromise + bypassing Trivy
- **Path 4 (Manifest Tampering):** LOW risk - Kyverno policy blocks deployment

---

## 5. DREAD Risk Scoring Summary

### 5.1 Top 10 Threats by Risk Score

| Rank | Threat ID | Threat Category | DREAD Score | Risk Level | Status |
|------|-----------|----------------|-------------|------------|--------|
| 1 | **I-03** | Information Disclosure (hardcoded secrets) | **25/25** | **CRITICAL** | ✅ **MITIGATED** (SR-07, gitignore, Bandit scanning) |
| 2 | **D-01** | Denial of Service (API flooding) | **24/25** | **CRITICAL** | ⚠️ **PARTIAL** (HPA enabled, rate limiting needed) |
| 3 | **R-01** | Repudiation (vote denial) | **21/25** | **HIGH** | ✅ **MITIGATED** (SR-12 audit logs) |
| 4 | **R-02** | Repudiation (admin result tampering) | **21/25** | **HIGH** | ✅ **MITIGATED** (SR-12 audit logs) |
| 5 | **T-02** | Tampering (election config modification) | **20/25** | **HIGH** | ✅ **MITIGATED** (SR-04 RBAC) |
| 6 | **E-04** | Elevation of Privilege (Jenkins pivot) | **20/25** | **HIGH** | ⚠️ **PARTIAL** (Jenkins auth, limited RBAC) |
| 7 | **D-02** | Denial of Service (database resource exhaustion) | **19/25** | **HIGH** | ✅ **MITIGATED** (resource limits, query validation) |
| 8 | **S-01** | Spoofing (credential theft) | **18/25** | **HIGH** | ⚠️ **PARTIAL** (bcrypt hashing, MFA needed) |
| 9 | **S-03** | Spoofing (XSS session hijacking) | **18/25** | **HIGH** | ⚠️ **PARTIAL** (input validation, HttpOnly cookies needed) |
| 10 | **T-01** | Tampering (vote record modification) | **17/25** | **MEDIUM** | ✅ **MITIGATED** (SR-10 parameterized queries) |

### 5.2 Risk Heatmap

```
⚠️ DIAGRAM REQUIRED HERE - Risk Heatmap (Likelihood vs Impact)
X-axis: Likelihood (1=Rare, 2=Unlikely, 3=Possible, 4=Likely, 5=Almost Certain)
Y-axis: Impact (1=Negligible, 2=Minor, 3=Moderate, 4=Major, 5=Catastrophic)

High-Risk Zone (Red, top-right):
- D-01 (API flooding DDoS) - Likelihood 5, Impact 4
- I-03 (Hardcoded secrets) - Likelihood 5, Impact 5 [MITIGATED]
- E-04 (Jenkins pivot) - Likelihood 3, Impact 5

Medium-Risk Zone (Yellow, center):
- S-01 (Credential theft) - Likelihood 3, Impact 4
- S-03 (XSS hijacking) - Likelihood 3, Impact 4
- T-02 (Election tampering) - Likelihood 3, Impact 5 [MITIGATED]

Low-Risk Zone (Green, bottom-left):
- T-01 (SQL injection) - Likelihood 2, Impact 5 [MITIGATED]
- E-01 (JWT privilege escalation) - Likelihood 2, Impact 5 [MITIGATED]
- I-02 (MITM attack) - Likelihood 2, Impact 4 [MITIGATED]

Tools: Excel heatmap template, PowerPoint 5x5 grid, or Lucidchart
Estimated time: 10 minutes
```

---

## 6. Mitigations & Security Controls

### 6.1 Implemented Controls (Mapped to SRD Requirements)

| Control ID | Control Type | Description | Threats Mitigated | SRD Requirement |
|------------|-------------|-------------|-------------------|------------------|
| **C-01** | Authentication | Bcrypt password hashing (cost factor 12) | S-01, I-01 | SR-01 |
| **C-02** | Authentication | Generic login error messages (no user enumeration) | S-01, I-04 | SR-02 |
| **C-03** | Session Management | JWT token expiry (60 minutes) | S-02, S-03 | SR-03 |
| **C-04** | Authorization | RBAC enforcement for admin endpoints | T-02, E-01 | SR-04 |
| **C-05** | Cryptography | JWT signature validation (prevents tampering) | S-02, E-01 | SR-05 |
| **C-06** | Cryptography | TLS 1.3 for all data-in-transit | I-02 | SR-06 |
| **C-07** | Secrets Management | No hardcoded secrets (Jenkins credentials) | I-03 | SR-07 |
| **C-08** | Cryptography | AES-256 encryption for data-at-rest | I-01 | SR-08 |
| **C-09** | Input Validation | Pydantic schema validation | T-01, S-03 | SR-09 |
| **C-10** | Input Validation | SQLAlchemy ORM (parameterized queries) | T-01 | SR-10 |
| **C-11** | Logging | Authentication event logging | R-01, R-02 | SR-11 |
| **C-12** | Logging | Audit trails for security-critical events | R-01, R-02 | SR-12 |
| **C-13** | Infrastructure | Non-root containers (Kyverno policy) | E-02 | SR-13 |
| **C-14** | Infrastructure | Container vulnerability scanning (Trivy) | T-03, E-02 | SR-14 |
| **C-15** | DevSecOps | Automated security testing (12+ scans) | All categories | SR-15 |

### 6.2 Recommended Future Enhancements

| Enhancement ID | Control Type | Description | Threats Addressed | Priority | Effort |
|----------------|-------------|-------------|-------------------|----------|--------|
| **FE-01** | Authentication | Multi-factor authentication (TOTP/SMS) | S-01 (credential theft) | **HIGH** | 2-3 weeks |
| **FE-02** | Rate Limiting | API rate limiting (100 req/min per IP) | D-01 (DDoS attacks) | **CRITICAL** | 1 week |
| **FE-03** | Session Security | HttpOnly + Secure cookies (instead of localStorage) | S-03 (XSS session hijacking) | **HIGH** | 1 week |
| **FE-04** | Cryptography | Docker image signing (Cosign/Notary) | T-03 (image tampering) | **MEDIUM** | 2 weeks |
| **FE-05** | Logging | External SIEM integration (Splunk/ELK) | R-03 (log deletion) | **MEDIUM** | 2-3 weeks |
| **FE-06** | Integrity | Cryptographic vote hashing (blockchain-style) | T-01, R-01 | **LOW** | 4+ weeks |
| **FE-07** | Network Security | Web Application Firewall (AWS WAF) | Multiple (SQLi, XSS, DDoS) | **MEDIUM** | 1-2 weeks |

---

## 7. Security Testing Coverage

### 7.1 Threat-to-Test Mapping

| Threat Category | Testing Method | Tools | Threats Validated | Frequency |
|-----------------|---------------|-------|-------------------|-----------||
| **Spoofing** | SAST (credential detection), Unit tests (JWT validation) | Bandit, Ruff, PyTest | S-01, S-02, S-03 | Every commit |
| **Tampering** | DAST (SQLi testing), IaC scanning, SCA | OWASP ZAP, Checkov, Safety | T-01, T-02, T-03, T-04 | Every build |
| **Repudiation** | Manual log review, Loki query validation | Grafana, Loki LogQL | R-01, R-02, R-03 | Post-deployment |
| **Information Disclosure** | Container scanning, SAST (hardcoded secrets), TLS testing | Trivy, Bandit, Nmap/SSLyze | I-01, I-02, I-03, I-04 | Every build |
| **Denial of Service** | Load testing, Resource limit validation | k6/Locust (future), Kyverno reports | D-01, D-02, D-03, D-04 | Pre-release |
| **Elevation of Privilege** | RBAC unit tests, Runtime monitoring, Policy validation | PyTest, Falco, Kyverno | E-01, E-02, E-03, E-04 | Every commit + runtime |

---

## 8. Incident Response Scenarios

### 8.1 Scenario 1: Suspected Vote Tampering (T-02)

**Detection:**
- Grafana alert: Unusual spike in `/elections/{id}/tally` requests
- Falco alert: Unauthorized file modification in PostgreSQL container

**Response Steps:**
1. **Contain (< 5 min):** Revoke suspected admin JWT tokens via database flag
2. **Investigate (< 30 min):** Query Loki logs: `{app="backend"} |= "/elections" | json | role="admin"`
3. **Analyze (< 1 hour):** Compare vote tallies before/after suspicious activity using PostgreSQL audit log
4. **Recover (< 2 hours):** Rollback to last known-good database snapshot (StatefulSet backup)
5. **Post-Incident (< 1 day):** Generate incident report, review RBAC policies, implement FE-01 (MFA)

### 8.2 Scenario 2: DDoS Attack on API (D-01)

**Detection:**
- Prometheus alert: `http_requests_total{status=~"5.."}` > 100 req/sec for 5 minutes
- Kubernetes HPA: Pods scaled to maximum (10 replicas) with high CPU

**Response Steps:**
1. **Contain (< 2 min):** Enable AWS ALB rate limiting (if available) or emergency maintenance mode
2. **Investigate (< 15 min):** Analyze Nginx access logs for top source IPs: `kubectl logs -n default svc/frontend | grep "GET /api"`
3. **Mitigate (< 30 min):** Block top 10 attacking IPs in Kubernetes NetworkPolicy
4. **Recover (< 1 hour):** Gradually restore service, monitor for continued attacks
5. **Post-Incident (< 2 days):** Implement FE-02 (rate limiting), configure CloudFlare DDoS protection

---

## 9. Compliance & Regulatory Impact

### 9.1 GDPR Threat Considerations

| GDPR Article | Relevant Threats | Compliance Controls |
|--------------|------------------|---------------------|
| **Art. 32 (Security)** | I-01, I-02, I-03 (data breaches) | SR-06 (TLS), SR-08 (encryption), SR-14 (vulnerability scanning) |
| **Art. 33 (Breach Notification)** | All threat categories (72-hour reporting) | SR-12 (audit logs), incident response runbook in `docs/OPERATIONS.md` |
| **Art. 5 (Data Minimization)** | I-01, I-04 (excessive data collection) | Only email + hashed password stored; no names, addresses, or phone numbers |

### 9.2 OWASP ASVS Threat Coverage

| ASVS Category | Threats Addressed | Compliance Level |
|---------------|-------------------|------------------|
| **V2: Authentication** | S-01, S-02, S-03, I-04 | Level 2 (MFA required for Level 3) |
| **V4: Access Control** | E-01, E-02, E-03, T-02 | Level 3 (full RBAC + runtime enforcement) |
| **V5: Validation** | T-01, S-03 | Level 2 (advanced XSS/CSP needed for Level 3) |
| **V7: Logging** | R-01, R-02, R-03 | Level 2 (external SIEM needed for Level 3) |

---

## 10. Threat Model Maintenance

### 10.1 Review Schedule
- **Weekly (During Development):** Update threat model when new features added (e.g., admin dashboard, vote export)
- **Monthly (Post-Deployment):** Review Falco/Loki alerts for new attack patterns
- **Quarterly:** Full STRIDE analysis with updated DREAD scores based on real-world incidents
- **Annually:** External penetration testing, compare findings against threat model

### 10.2 Trigger Events for Re-Assessment
- New external integration (e.g., OAuth provider, payment gateway)
- Major architecture change (e.g., migrate from Minikube to AWS EKS)
- Security incident or near-miss
- New vulnerability disclosure affecting dependencies (e.g., Log4Shell-style event)

---

## 11. References

1. **STRIDE Methodology:** Microsoft Security Development Lifecycle (SDL)
2. **DREAD Risk Scoring:** Microsoft Threat Modeling Framework
3. **OWASP Threat Modeling Cheat Sheet:** https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
4. **MITRE ATT&CK Framework:** https://attack.mitre.org/ (for advanced persistent threat analysis)
5. **Project Requirements:** `ssddlabfinal/project.md` (CYC386 Lab Brief)
6. **Security Requirements Document:** `docs/srd.md` (mitigation mappings)
7. **Architecture Documentation:** `docs/architecture.md` (system context, data flows)

---

**Document Status:** ✅ FINAL (Version 1.0)  
**Next Review:** Post-deployment security testing (Week 15)  
**Approval Required:** Instructor sign-off for final defense
- Infrastructure boundary includes Kubernetes cluster nodes isolated via Terraform-managed security groups and network policies.
- Use cases of registration, voting, tallying each require fresh threats per STRIDE row above.
