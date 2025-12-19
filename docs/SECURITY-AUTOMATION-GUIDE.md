# Security Automation Reference Card

## 🤖 What's Automated vs 🧑 What's Manual

| Security Feature | Status | How | When |
|-----------------|--------|-----|------|
| **EBS Encryption** | 🧑 Manual | AWS Console during launch | Pre-launch |
| **IMDSv2 Enforcement** | 🧑 Manual | AWS Console advanced settings | Pre-launch |
| **IAM Role Creation** | 🧑 Manual | AWS IAM Console | Pre-launch |
| **Security Group** | 🧑 Manual | AWS EC2 Console | Pre-launch |
| **SSH Key Generation** | 🧑 Manual | AWS Console key pair | Pre-launch |
| **Elastic IP** | 🧑 Manual | AWS EC2 Console | Post-launch |
| **Secrets Manager Setup** | 🧑 Manual | AWS Secrets Manager Console | Post-launch |
| **Docker Installation** | 🧑 Manual | SSH commands | Post-launch |
| **Minikube Installation** | 🧑 Manual | SSH commands | Post-launch |
| **Jenkins Installation** | 🧑 Manual | SSH commands | Post-launch |
| **Jenkins Configuration** | 🧑 Manual | Jenkins Web UI | Post-launch |
| **GitHub Webhook** | 🧑 Manual | GitHub Settings | Post-launch |
| **SSH Hardening** | 🤖 Automated | Jenkins pipeline script | First pipeline run |
| **UFW Firewall** | 🤖 Automated | Jenkins pipeline script | First pipeline run |
| **Fail2Ban** | 🤖 Automated | Jenkins pipeline script | First pipeline run |
| **Auto Security Updates** | 🤖 Automated | Jenkins pipeline script | First pipeline run |
| **CloudWatch Agent** | 🤖 Automated | Jenkins pipeline script | First pipeline run |
| **Secrets Retrieval** | 🤖 Automated | Jenkins pipeline script | Every pipeline run |
| **K8s Secrets Creation** | 🤖 Automated | Jenkins pipeline script | Every pipeline run |
| **Kyverno Installation** | 🤖 Automated | Jenkins pipeline script | When INSTALL_POLICIES=true |
| **OPA Gatekeeper** | 🤖 Automated | Jenkins pipeline script | When INSTALL_POLICIES=true |
| **Policy Enforcement** | 🤖 Automated | Jenkins pipeline script | When INSTALL_POLICIES=true |
| **Monitoring Stack** | 🤖 Automated | Jenkins pipeline script | When INSTALL_MONITORING=true |

---

## 📝 Jenkins Pipeline Parameters

When running the pipeline, you'll see these checkboxes:

```
☐ DEPLOY_TO_K8S (default: false)
   Deploy application to Kubernetes cluster

☐ INSTALL_MONITORING (default: false)
   Install Prometheus, Grafana, Loki, Falco stack

☑ SETUP_SECURITY (default: true)
   Run security hardening scripts
   - SSH hardening (key-only auth)
   - UFW firewall configuration
   - Fail2Ban setup
   - Automatic security updates
   - CloudWatch agent installation
   - Security verification

☑ USE_SECRETS_MANAGER (default: true)
   Retrieve secrets from AWS Secrets Manager
   Falls back to Jenkins credentials if unavailable

☐ INSTALL_POLICIES (default: false)
   Install and configure policy engines
   - Kyverno (3 policies)
   - OPA Gatekeeper (3 constraints)
```

---

## 🚀 Common Pipeline Scenarios

### Scenario 1: First-Time Setup (Full Deployment)
```
✓ SETUP_SECURITY: true
✓ USE_SECRETS_MANAGER: true
✓ DEPLOY_TO_K8S: true
✓ INSTALL_MONITORING: true
✓ INSTALL_POLICIES: true

Duration: ~25-30 minutes
What happens:
1. System hardening (SSH, firewall, fail2ban, updates, CloudWatch)
2. Secrets retrieval from AWS Secrets Manager
3. Code build and security scans (Trivy)
4. Docker image push
5. Policy engine installation (Kyverno + Gatekeeper)
6. Application deployment (Helm)
7. Monitoring stack deployment
8. Port forwarding setup
9. Security validation
```

### Scenario 2: Code Update (No Infrastructure Changes)
```
☐ SETUP_SECURITY: false (already done)
☐ USE_SECRETS_MANAGER: false (secrets already in K8s)
✓ DEPLOY_TO_K8S: true
☐ INSTALL_MONITORING: false (already installed)
☐ INSTALL_POLICIES: false (already installed)

Duration: ~8-10 minutes
What happens:
1. Code fetch
2. Build and test
3. Docker image creation
4. Security scanning
5. Image push
6. Helm upgrade (rolling update)
7. Security validation
```

### Scenario 3: Build Only (No Deployment)
```
☐ SETUP_SECURITY: false
☐ USE_SECRETS_MANAGER: false
☐ DEPLOY_TO_K8S: false
☐ INSTALL_MONITORING: false
☐ INSTALL_POLICIES: false

Duration: ~5-7 minutes
What happens:
1. Code fetch
2. Backend tests (ruff, bandit, pytest)
3. Frontend build
4. Docker image creation
5. Trivy security scans
6. Image push to DockerHub
```

### Scenario 4: Re-run Security Hardening
```
✓ SETUP_SECURITY: true
☐ USE_SECRETS_MANAGER: false
☐ DEPLOY_TO_K8S: false
☐ INSTALL_MONITORING: false
☐ INSTALL_POLICIES: false

Duration: ~3-5 minutes
What happens:
1. SSH hardening check/re-apply
2. UFW firewall check/re-apply
3. Fail2Ban check/re-apply
4. Auto-updates check/re-apply
5. CloudWatch agent check/re-apply
6. Security verification report
```

---

## 🔍 Security Script Details

### 1. harden-ssh.sh
**What it does:**
- Disables password authentication
- Disables root login
- Enables public key authentication only
- Sets MaxAuthTries to 3
- Disables X11 forwarding
- Creates backup of original config

**Idempotent:** ✅ Yes (safe to run multiple times)

**Manual verification:**
```bash
sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config
# Should show: PasswordAuthentication no
```

---

### 2. setup-firewall.sh
**What it does:**
- Installs UFW (if not present)
- Sets default deny incoming / allow outgoing
- Opens required ports (22, 80, 443, 8080, etc.)
- Allows internal VPC communication
- Enables firewall

**Idempotent:** ✅ Yes (checks if already active)

**Manual verification:**
```bash
sudo ufw status numbered
# Should show ~10 rules, Status: active
```

---

### 3. setup-fail2ban.sh
**What it does:**
- Installs Fail2Ban
- Configures SSH jail (3 attempts, 1hr ban)
- Configures Jenkins jail (5 attempts, 30min ban)
- Enables service

**Idempotent:** ✅ Yes (checks if already running)

**Manual verification:**
```bash
sudo fail2ban-client status sshd
# Should show: Currently banned: 0
```

---

### 4. setup-auto-updates.sh
**What it does:**
- Installs unattended-upgrades
- Configures automatic security updates
- Sets daily check schedule
- Configures no automatic reboot

**Idempotent:** ✅ Yes (checks if config exists)

**Manual verification:**
```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
# Should show periodic update enabled
```

---

### 5. setup-cloudwatch.sh
**What it does:**
- Downloads and installs CloudWatch agent
- Creates config for log collection:
  - /var/log/syslog
  - /var/log/auth.log
  - /var/lib/jenkins/logs/jenkins.log
  - /var/log/docker.log
- Configures CPU/memory/disk metrics
- Starts agent service

**Idempotent:** ✅ Yes (checks if already running)

**Manual verification:**
```bash
sudo systemctl status amazon-cloudwatch-agent
# Should show: active (running)

aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/voting-system"
# Should list 4 log groups
```

---

### 6. setup-secrets-manager.sh
**What it does:**
- Verifies AWS CLI and IAM role
- Retrieves secrets from Secrets Manager:
  - voting/database/credentials
  - voting/backend/secret-key
  - voting/backend/encryption-key
- Creates Kubernetes secret: voting-secrets
- Falls back to Jenkins credentials if AWS unavailable

**Idempotent:** ✅ Yes (checks if K8s secret exists, skips if found)

**Manual verification:**
```bash
kubectl get secret voting-secrets -n voting-system
# Should show: voting-secrets exists

kubectl get secret voting-secrets -n voting-system -o jsonpath='{.data}' | jq
# Should show 4 base64-encoded secrets
```

---

### 7. verify-security.sh
**What it does:**
- Runs comprehensive security checks:
  - EBS encryption status
  - IMDSv2 token enforcement
  - SSH hardening (3 checks)
  - UFW firewall active
  - Fail2Ban running
  - CloudWatch agent running
  - IAM role attached
  - Secrets Manager access
  - Kubernetes secrets
  - Automatic updates configured
- Reports PASS/FAIL for each check
- Returns exit code 0 only if all pass

**Idempotent:** ✅ Yes (read-only verification)

**Manual run:**
```bash
./ssddlabfinal/scripts/verify-security.sh
```

---

## 🔐 Secrets Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│           AWS Secrets Manager (Manual Setup)             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ voting/database/credentials                      │   │
│  │ voting/backend/secret-key                        │   │
│  │ voting/backend/encryption-key                    │   │
│  │ voting/jenkins/admin                             │   │
│  └─────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ IAM Role: voting-ec2-instance-role
                           │ (attached to EC2)
                           ▼
┌─────────────────────────────────────────────────────────┐
│         Jenkins Pipeline (Automated Retrieval)           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ setup-secrets-manager.sh                         │   │
│  │ - Calls AWS CLI with IAM role                    │   │
│  │ - Parses JSON responses                          │   │
│  │ - Falls back to Jenkins credentials if fail      │   │
│  └─────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ kubectl create secret
                           ▼
┌─────────────────────────────────────────────────────────┐
│         Kubernetes Cluster (Runtime Secrets)             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Secret: voting-secrets (namespace: voting-system)│   │
│  │ - database_url: postgresql://...                 │   │
│  │ - secret_key: <JWT secret>                       │   │
│  │ - postgres_password: <DB password>               │   │
│  │ - vote_encryption_key: <AES key>                 │   │
│  └─────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ envFrom: secretRef
                           ▼
┌─────────────────────────────────────────────────────────┐
│           Application Pods (Environment Variables)       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Backend Pod                                       │   │
│  │ - DATABASE_URL (from secret)                     │   │
│  │ - SECRET_KEY (from secret)                       │   │
│  │ - VOTE_ENCRYPTION_KEY (from secret)              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Pipeline Execution Timeline

```
First-Time Full Deployment (~30 minutes)

00:00 │ ════════════════ Stage 1: System Security Hardening ════════════════
      │ • SSH hardening                                          [1 min]
      │ • UFW firewall setup                                     [1 min]
      │ • Fail2Ban installation                                  [2 min]
      │ • Auto-updates configuration                             [1 min]
      │ • CloudWatch agent installation                          [3 min]
      │ • Security verification                                  [1 min]
      │
09:00 │ ════════════════ Stage 2: AWS Secrets Manager ═══════════════════
      │ • Verify IAM role                                        [10 sec]
      │ • Retrieve 4 secrets                                     [5 sec]
      │ • Create K8s secret                                      [5 sec]
      │
09:30 │ ════════════════ Stage 3: Code Fetch ════════════════════════════
      │ • Git clone/checkout                                     [30 sec]
      │
10:00 │ ════════════════ Stage 4: Build & Test ══════════════════════════
      │ • Backend: pip install, ruff, bandit, pytest            [3 min]
      │ • Frontend: npm ci, build                                [2 min]
      │ • Docker image builds (2 images)                         [4 min]
      │ • Trivy security scans                                   [2 min]
      │
21:00 │ ════════════════ Stage 5: Image Push ════════════════════════════
      │ • Push 4 images to DockerHub                            [3 min]
      │
24:00 │ ════════════════ Stage 6: Policy Engines ════════════════════════
      │ • Install Kyverno                                        [2 min]
      │ • Apply Kyverno policies                                 [30 sec]
      │ • Install OPA Gatekeeper                                 [2 min]
      │ • Apply Gatekeeper constraints                           [30 sec]
      │
29:00 │ ════════════════ Stage 7: Application Deployment ════════════════
      │ • Helm install voting-system                            [2 min]
      │ • Wait for rollout (3 deployments)                      [3 min]
      │
34:00 │ ════════════════ Stage 8: Monitoring Stack ══════════════════════
      │ • Install kube-prometheus-stack                         [5 min]
      │ • Install Loki                                           [2 min]
      │ • Install Falco                                          [2 min]
      │ • Apply alert rules                                      [30 sec]
      │
43:30 │ ════════════════ Stage 9: Port Forwarding ═══════════════════════
      │ • Setup 4 port forwards (backend, frontend, grafana, prometheus)
      │                                                           [30 sec]
      │
44:00 │ ════════════════ Stage 10: Security Validation ══════════════════
      │ • Check security contexts                                [30 sec]
      │ • Check resource limits                                  [10 sec]
      │ • Check network policies                                 [10 sec]
      │ • Test health endpoints                                  [10 sec]
      │
45:00 │ ══════════════════ Pipeline Complete ═══════════════════════════
      │ ✓ All stages successful
      │ ✓ Application accessible at http://YOUR_IP:8000
      │ ✓ Monitoring at http://YOUR_IP:3000
```

---

## 🎓 Best Practices

### 1. First Run
- ✅ Enable ALL parameters for first pipeline run
- ✅ Monitor Jenkins console output
- ✅ Verify each stage completes successfully
- ✅ Run `verify-security.sh` manually to confirm

### 2. Subsequent Runs
- ✅ Disable SETUP_SECURITY (only needed once)
- ✅ Disable INSTALL_POLICIES (only needed once)
- ✅ Keep USE_SECRETS_MANAGER enabled (idempotent)
- ✅ Enable DEPLOY_TO_K8S for updates

### 3. Troubleshooting
- ✅ Check Jenkins console logs first
- ✅ SSH into EC2 and check script logs in /tmp
- ✅ Verify IAM role attached: `aws sts get-caller-identity`
- ✅ Check pod logs: `kubectl logs -n voting-system <pod-name>`
- ✅ Review security group rules in AWS Console

### 4. Security
- ❌ Never commit secrets to Git
- ❌ Never hardcode credentials in Jenkinsfile
- ✅ Always use Secrets Manager or Jenkins credentials
- ✅ Rotate secrets regularly (every 90 days)
- ✅ Monitor CloudWatch logs for suspicious activity

---

**Quick Reference Card Version**: 1.0  
**Last Updated**: December 19, 2025
