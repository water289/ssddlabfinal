# Security Automation Scripts

This directory contains shell scripts for automated security hardening and configuration of the EC2 instance. All scripts are **idempotent** (safe to run multiple times) and are automatically executed by the Jenkins pipeline.

---

## 📁 Script Inventory

| Script | Purpose | Execution Time | Jenkins Stage |
|--------|---------|----------------|---------------|
| `harden-ssh.sh` | SSH security hardening | ~30 sec | System Security Hardening |
| `setup-firewall.sh` | UFW firewall configuration | ~1 min | System Security Hardening |
| `setup-fail2ban.sh` | Intrusion prevention setup | ~2 min | System Security Hardening |
| `setup-auto-updates.sh` | Automatic security updates | ~1 min | System Security Hardening |
| `setup-cloudwatch.sh` | CloudWatch Logs Agent | ~3 min | System Security Hardening |
| `setup-secrets-manager.sh` | AWS Secrets retrieval | ~20 sec | AWS Secrets Manager Integration |
| `verify-security.sh` | Security validation | ~1 min | System Security Hardening |

---

## 🔧 Script Details

### 1. harden-ssh.sh

**Purpose**: Enforce SSH key-only authentication and disable insecure options.

**What it does**:
- Disables password authentication
- Disables root login via SSH
- Enables public key authentication
- Sets MaxAuthTries to 3
- Disables X11 forwarding
- Creates backup of original config at `/etc/ssh/sshd_config.backup`
- Tests configuration before applying
- Restarts SSH service

**Requirements**: None (uses built-in sshd)

**Output**:
```
=== SSH Hardening ===
Backing up original SSH configuration...
Hardening SSH configuration...
Testing SSH configuration...
Restarting SSH service...
✓ SSH hardened successfully
Configuration summary:
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
=== SSH hardening complete ===
```

**Idempotency**: ✅ Checks if already configured, skips if PasswordAuthentication already disabled

**Manual execution**:
```bash
sudo ./harden-ssh.sh
```

**Rollback**:
```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd
```

---

### 2. setup-firewall.sh

**Purpose**: Configure UFW firewall with application-specific rules.

**What it does**:
- Installs UFW if not present
- Sets default deny incoming / allow outgoing
- Opens required ports:
  - 22 (SSH)
  - 80/443 (HTTP/HTTPS)
  - 8080 (Jenkins)
  - 8000 (Backend API)
  - 5173 (Frontend)
  - 3000 (Grafana)
  - 9090 (Prometheus)
  - 30000-32767 (Kubernetes NodePort)
- Allows internal VPC traffic (10.0.0.0/16)
- Allows Docker bridge (172.17.0.0/16)
- Allows Minikube (192.168.49.0/24)
- Enables firewall

**Requirements**: None (installs UFW via apt)

**Output**:
```
=== UFW Firewall Setup ===
Installing UFW...
Configuring UFW firewall rules...
Enabling UFW...
✓ UFW firewall configured and enabled
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
...
=== Firewall setup complete ===
```

**Idempotency**: ✅ Checks if UFW already active, skips if Status: active

**Manual execution**:
```bash
sudo ./setup-firewall.sh
```

**Verify**:
```bash
sudo ufw status numbered
```

**Disable** (for troubleshooting):
```bash
sudo ufw disable
```

---

### 3. setup-fail2ban.sh

**Purpose**: Install and configure Fail2Ban for brute-force protection.

**What it does**:
- Installs Fail2Ban package
- Creates `/etc/fail2ban/jail.local` with:
  - bantime: 3600 seconds (1 hour)
  - findtime: 600 seconds (10 minutes)
  - maxretry: 3 attempts
- Configures SSH jail (monitors `/var/log/auth.log`)
- Configures Jenkins jail (monitors `/var/lib/jenkins/logs/jenkins.log`)
- Starts and enables service

**Requirements**: None (installs fail2ban via apt)

**Output**:
```
=== Fail2Ban Setup ===
Installing Fail2Ban...
Configuring Fail2Ban...
Starting Fail2Ban service...
✓ Fail2Ban running successfully
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
=== Fail2Ban setup complete ===
```

**Idempotency**: ✅ Checks if already running, skips if active

**Manual execution**:
```bash
sudo ./setup-fail2ban.sh
```

**Check banned IPs**:
```bash
sudo fail2ban-client status sshd
```

**Unban IP**:
```bash
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

### 4. setup-auto-updates.sh

**Purpose**: Configure automatic security updates for Ubuntu.

**What it does**:
- Installs `unattended-upgrades` package
- Configures automatic updates for:
  - Security updates
  - ESM security updates
- Creates `/etc/apt/apt.conf.d/50unattended-upgrades` with:
  - Automatic reboot: disabled
  - Remove unused dependencies: enabled
  - Remove unused kernels: enabled
- Creates `/etc/apt/apt.conf.d/20auto-upgrades` with:
  - Daily package list updates
  - Daily security updates
  - Weekly cleanup
- Tests configuration

**Requirements**: None (installs unattended-upgrades via apt)

**Output**:
```
=== Automatic Security Updates Setup ===
Installing unattended-upgrades...
Configuring automatic security updates...
Testing unattended-upgrades configuration...
Initial debug solving dependencies tree... Done
Building data structures... Done
✓ Automatic security updates configured
=== Auto-updates setup complete ===
```

**Idempotency**: ✅ Checks if config exists, skips if already configured

**Manual execution**:
```bash
sudo ./setup-auto-updates.sh
```

**Check update status**:
```bash
sudo unattended-upgrades --dry-run
```

**View update logs**:
```bash
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

---

### 5. setup-cloudwatch.sh

**Purpose**: Install and configure AWS CloudWatch Logs Agent.

**What it does**:
- Downloads CloudWatch agent package from S3
- Installs agent via dpkg
- Creates `/opt/aws/amazon-cloudwatch-agent/etc/config.json` with:
  - Log groups:
    - `/aws/ec2/voting-system/syslog` (7-day retention)
    - `/aws/ec2/voting-system/auth` (30-day retention)
    - `/aws/ec2/voting-system/jenkins` (14-day retention)
    - `/aws/ec2/voting-system/docker` (7-day retention)
  - Metrics:
    - CPU usage (idle, iowait)
    - Disk usage (percent)
    - Memory usage (percent)
- Starts agent with config
- Enables auto-start on boot

**Requirements**: IAM role with CloudWatch permissions

**Output**:
```
=== CloudWatch Logs Agent Setup ===
Installing CloudWatch agent...
Creating CloudWatch agent configuration...
Starting CloudWatch agent...
✓ CloudWatch agent running successfully
=== CloudWatch setup complete ===
```

**Idempotency**: ✅ Checks if already running, skips if active

**Manual execution**:
```bash
sudo ./setup-cloudwatch.sh
```

**Check agent status**:
```bash
sudo systemctl status amazon-cloudwatch-agent
```

**View agent logs**:
```bash
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

**Restart agent**:
```bash
sudo systemctl restart amazon-cloudwatch-agent
```

---

### 6. setup-secrets-manager.sh

**Purpose**: Retrieve secrets from AWS Secrets Manager and create Kubernetes secrets.

**What it does**:
- Verifies AWS CLI installed (installs if missing)
- Verifies jq installed (installs if missing)
- Checks IAM role authentication
- Retrieves 4 secrets from Secrets Manager:
  - `voting/database/credentials` (username, password)
  - `voting/backend/secret-key` (JWT secret)
  - `voting/backend/encryption-key` (AES-256 key)
- Falls back to Jenkins credentials if Secrets Manager unavailable
- Creates Kubernetes namespace `voting-system`
- Creates Kubernetes secret `voting-secrets` with:
  - database_url
  - secret_key
  - postgres_password
  - vote_encryption_key
- Exports secrets to `$WORKSPACE/secrets.env` for Jenkins

**Requirements**: 
- IAM role with `secretsmanager:GetSecretValue`
- Kubernetes cluster accessible via kubectl

**Output**:
```
=== AWS Secrets Manager Setup ===
Verifying AWS credentials...
Retrieving secrets from AWS Secrets Manager...
Retrieving secret: voting/database/credentials
Retrieving secret: voting/backend/secret-key
Retrieving secret: voting/backend/encryption-key
Creating Kubernetes namespace if not exists...
Creating Kubernetes secret...
✓ Secrets retrieved and stored in Kubernetes
Exporting secrets to Jenkins environment...
=== Secrets setup complete ===
```

**Idempotency**: ✅ Checks if K8s secret exists, skips retrieval if found

**Manual execution**:
```bash
export AWS_REGION=us-east-1
export K8S_NAMESPACE=voting-system
./setup-secrets-manager.sh
```

**Verify secrets**:
```bash
kubectl get secret voting-secrets -n voting-system
kubectl get secret voting-secrets -n voting-system -o jsonpath='{.data}' | jq
```

**Force re-retrieval**:
```bash
kubectl delete secret voting-secrets -n voting-system
./setup-secrets-manager.sh
```

---

### 7. verify-security.sh

**Purpose**: Comprehensive security validation checks.

**What it does**:
- Checks EBS encryption status
- Tests IMDSv2 token enforcement
- Verifies SSH hardening (3 checks):
  - Password authentication disabled
  - Root login disabled
  - Public key authentication enabled
- Checks UFW firewall active
- Checks Fail2Ban running
- Checks CloudWatch agent running
- Verifies IAM role attached
- Tests Secrets Manager access
- Checks Kubernetes secrets exist
- Verifies automatic updates configured
- Reports PASS/FAIL count
- Returns exit code 0 only if all checks pass

**Requirements**: None (all checks are read-only)

**Output**:
```
==========================================
  SECURITY CONFIGURATION VERIFICATION
==========================================

=== Storage Security ===
Checking EBS Encryption... ✓ PASS

=== Instance Metadata Security ===
Checking IMDSv2 enforcement... ✓ PASS

=== SSH Security ===
Checking Password authentication disabled... ✓ PASS
Checking Root login disabled... ✓ PASS
Checking Public key authentication enabled... ✓ PASS

=== Firewall Security ===
Checking UFW firewall active... ✓ PASS

=== Intrusion Prevention ===
Checking Fail2Ban running... ✓ PASS

=== Monitoring ===
Checking CloudWatch agent running... ✓ PASS

=== IAM Security ===
Checking IAM role attachment... ✓ PASS

=== Secrets Management ===
Checking Secrets Manager access... ✓ PASS

=== Kubernetes Security ===
Checking Kubernetes secrets exist... ✓ PASS

=== System Maintenance ===
Checking Automatic updates configured... ✓ PASS

==========================================
  VERIFICATION SUMMARY
==========================================
Passed: 11
Failed: 0

✓ All security checks passed!
```

**Idempotency**: ✅ Fully idempotent (read-only checks)

**Manual execution**:
```bash
./verify-security.sh
```

**Exit codes**:
- 0: All checks passed
- 1: One or more checks failed

---

## 🚀 Jenkins Integration

All scripts are automatically executed by the Jenkins pipeline. Here's how they're called:

```groovy
stage('System Security Hardening') {
  when { expression { return params.SETUP_SECURITY } }
  steps {
    sh 'chmod +x ssddlabfinal/scripts/*.sh'
    sh './ssddlabfinal/scripts/harden-ssh.sh'
    sh './ssddlabfinal/scripts/setup-firewall.sh'
    sh './ssddlabfinal/scripts/setup-fail2ban.sh'
    sh './ssddlabfinal/scripts/setup-auto-updates.sh'
    sh './ssddlabfinal/scripts/setup-cloudwatch.sh'
    sh './ssddlabfinal/scripts/verify-security.sh'
  }
}

stage('AWS Secrets Manager Integration') {
  when { expression { return params.USE_SECRETS_MANAGER && params.DEPLOY_TO_K8S } }
  steps {
    sh './ssddlabfinal/scripts/setup-secrets-manager.sh'
  }
}
```

---

## 🐛 Debugging

### Script execution logs

All scripts output to stdout/stderr. In Jenkins:
- View in Console Output: http://YOUR_IP:8080/job/secure-voting-pipeline/lastBuild/console
- Search for script name to jump to specific stage

### Manual script execution

```bash
# SSH into EC2
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP

# Navigate to repo
cd /path/to/repo

# Make scripts executable
chmod +x ssddlabfinal/scripts/*.sh

# Run individual script
sudo ./ssddlabfinal/scripts/harden-ssh.sh

# Check exit code
echo $?  # 0 = success, non-zero = error
```

### Common issues

**Issue**: "Permission denied"
```bash
chmod +x ssddlabfinal/scripts/*.sh
```

**Issue**: "AWS CLI not found" (in setup-secrets-manager.sh)
```bash
sudo apt-get update
sudo apt-get install -y awscli
```

**Issue**: "kubectl: command not found" (in setup-secrets-manager.sh)
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
```

**Issue**: "IAM role not attached" (in setup-secrets-manager.sh)
```bash
# Verify IAM role
aws sts get-caller-identity

# If shows error, attach role in AWS Console:
# EC2 → Instance → Actions → Security → Modify IAM role
```

---

## 📋 Testing Checklist

Before running in production, test each script individually:

```bash
# 1. SSH hardening
sudo ./ssddlabfinal/scripts/harden-ssh.sh
grep "^PasswordAuthentication" /etc/ssh/sshd_config  # Should be 'no'

# 2. Firewall
sudo ./ssddlabfinal/scripts/setup-firewall.sh
sudo ufw status  # Should show 'Status: active'

# 3. Fail2Ban
sudo ./ssddlabfinal/scripts/setup-fail2ban.sh
sudo fail2ban-client status  # Should show 'Number of jail: 1'

# 4. Auto-updates
sudo ./ssddlabfinal/scripts/setup-auto-updates.sh
cat /etc/apt/apt.conf.d/20auto-upgrades  # Should show enabled

# 5. CloudWatch
sudo ./ssddlabfinal/scripts/setup-cloudwatch.sh
sudo systemctl status amazon-cloudwatch-agent  # Should be 'active'

# 6. Secrets Manager (requires Minikube running)
minikube start
./ssddlabfinal/scripts/setup-secrets-manager.sh
kubectl get secret voting-secrets -n voting-system  # Should exist

# 7. Verification
./ssddlabfinal/scripts/verify-security.sh
# Should show all PASS
```

---

## 🔒 Security Considerations

1. **Secrets**: Never log sensitive values (all scripts use `echo` for status only)
2. **Permissions**: Scripts require sudo for system modifications (except verify-security.sh)
3. **Idempotency**: All scripts check current state before making changes
4. **Backups**: SSH hardening creates backup before modifying configs
5. **Error handling**: Scripts use `set -e` to exit on errors, preventing partial configurations

---

## 📚 Additional Resources

- [AWS CloudWatch Agent Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [AWS Secrets Manager CLI](https://docs.aws.amazon.com/cli/latest/reference/secretsmanager/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

---

**Scripts Version**: 1.0  
**Last Updated**: December 19, 2025  
**Maintainer**: DevSecOps Team
