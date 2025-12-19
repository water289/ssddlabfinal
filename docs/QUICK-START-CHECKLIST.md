# Quick Start Checklist - AWS EC2 Deployment

Print this page and check off each step as you complete it.

---

## ☑️ PHASE 1: AWS Console Setup (20 minutes)

### Step 1: Launch EC2 Instance
- [ ] EC2 → Launch Instance
- [ ] Name: `voting-jenkins-k8s-server`
- [ ] AMI: Ubuntu Server 22.04 LTS
- [ ] Instance type: `m7i.large`
- [ ] Key pair: Create new → Name: `voting-system-key` → Type: RSA → Format: .pem
- [ ] **Download and save .pem file securely!**
- [ ] Network: Create new VPC or use existing
- [ ] Auto-assign public IP: **Enable**
- [ ] Security group: Create new (see Step 3)
- [ ] Root volume: 80 GB, gp3, **Encrypted ✓**, Delete on termination: **No**
- [ ] Advanced details → Metadata version: **V2 only (token required) ✓**
- [ ] Launch instance

### Step 2: Configure Security Group
Create security group with these inbound rules:
- [ ] Port 22 (SSH) - Source: My IP
- [ ] Port 80 (HTTP) - Source: 0.0.0.0/0
- [ ] Port 443 (HTTPS) - Source: 0.0.0.0/0
- [ ] Port 8080 (Jenkins) - Source: My IP
- [ ] Port 8000 (Backend) - Source: 0.0.0.0/0
- [ ] Port 5173 (Frontend) - Source: 0.0.0.0/0
- [ ] Port 3000 (Grafana) - Source: My IP
- [ ] Port 9090 (Prometheus) - Source: My IP
- [ ] Port 30000-32767 (K8s NodePort) - Source: 0.0.0.0/0
- [ ] All traffic - Source: This security group (self-reference)
- [ ] All TCP - Source: 10.0.0.0/16 (internal VPC)

### Step 3: Allocate Elastic IP
- [ ] EC2 → Elastic IPs → Allocate Elastic IP
- [ ] Select IP → Actions → Associate Elastic IP
- [ ] Instance: Select `voting-jenkins-k8s-server`
- [ ] Associate
- [ ] **Write down Elastic IP**: `___.___.___.___`

---

## ☑️ PHASE 2: EC2 Initial Setup (45 minutes)

### Step 4: First SSH Connection
```bash
chmod 400 voting-system-key.pem
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP
```
- [ ] Successfully connected to EC2

### Step 5: Verify Storage
```bash
df -h /  # Check root volume size
# Should show approximately 80GB total

lsblk  # List block devices
# Should show single root volume
```
- [ ] Storage verified (80GB root volume)

### Step 6: System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```
- [ ] Wait 1 minute, then reconnect

### Step 7: Install Docker
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
exit
```
- [ ] Reconnect: `ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP`
- [ ] Test: `docker ps` (should work without sudo)

### Step 8: Install Minikube
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
kubectl get nodes  # Should show: minikube Ready
minikube addons enable metrics-server
minikube addons enable ingress
```
- [ ] Minikube cluster running

### Step 9: Install Jenkins
```bash
sudo apt-get install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
- [ ] **Write down initial password**: `______________________`
- [ ] Wait 2 minutes for Jenkins to start

---

## ☑️ PHASE 3: Jenkins Configuration (20 minutes)

### Step 10: Jenkins Initial Setup
- [ ] Open browser: `http://YOUR_ELASTIC_IP:8080`
- [ ] Paste initial admin password
- [ ] Select "Install suggested plugins"
- [ ] Wait 5-10 minutes for plugins to install
- [ ] Create admin user:
  - [ ] Username: `admin`
  - [ ] Password: `whoami@009`
  - [ ] Full name: Your Name
  - [ ] Email: your-email@example.com
- [ ] Jenkins URL: `http://YOUR_ELASTIC_IP:8080`
- [ ] Click "Save and Finish"

### Step 11: Install Additional Plugins
- [ ] Manage Jenkins → Plugins → Available plugins
- [ ] Search and install (check all 3):
  - [ ] **Warnings** (Warnings Next Generation - for Ruff/Bandit/ESLint)
  - [ ] **Code Coverage API** (for coverage trends)
  - [ ] **HTML Publisher Plugin** (for HTML reports)
- [ ] Click "Install"
- [ ] ✓ Restart Jenkins when installation is complete

### Step 12: Add Jenkins Credentials
Manage Jenkins → Credentials → System → Global credentials → Add Credentials

**Credential 1: DockerHub**
- [ ] Kind: Username with password
- [ ] Username: `water289` (your DockerHub username)
- [ ] Password: (your DockerHub access token)
- [ ] ID: `dockerhub-creds`
- [ ] Create

**Credential 2: Backend Secret Key**
- [ ] Kind: Secret text
- [ ] Secret: Generate new: `openssl rand -hex 32`
- [ ] ID: `secure-voting-secret-key`
- [ ] Create

**Credential 3: Postgres Password**
- [ ] Kind: Secret text
- [ ] Secret: Generate new: `openssl rand -base64 24`
- [ ] ID: `secure-voting-postgres-password`
- [ ] Create

### Step 13: Create Pipeline Job
- [ ] Dashboard → New Item
- [ ] Name: `secure-voting-pipeline`
- [ ] Type: Pipeline
- [ ] OK
- [ ] General → ✓ GitHub project: `https://github.com/YOUR_USERNAME/YOUR_REPO`
- [ ] Build Triggers → ✓ GitHub hook trigger for GITScm polling
- [ ] Pipeline:
  - [ ] Definition: Pipeline script from SCM
  - [ ] SCM: Git
  - [ ] Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO`
  - [ ] Branch: `*/main`
  - [ ] Script Path: `Jenkinsfile`
- [ ] Save

### Step 14: Configure GitHub Webhook
- [ ] GitHub → Your Repo → Settings → Webhooks → Add webhook
- [ ] Payload URL: `http://YOUR_ELASTIC_IP:8080/github-webhook/`
- [ ] Content type: `application/json`
- [ ] Events: Just the push event
- [ ] Active: ✓
- [ ] Add webhook
- [ ] Verify webhook shows green checkmark

---

## ☑️ PHASE 4: First Deployment (45 minutes)

### Step 15: Clone Repository on EC2
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```
- [ ] Repository cloned

### Step 16: Run First Jenkins Build
- [ ] Jenkins → secure-voting-pipeline → Build with Parameters
- [ ] Check parameters for first run:
  - [ ] ✓ DEPLOY_TO_K8S
  - [ ] ✓ INSTALL_MONITORING
  - [ ] ✓ SETUP_SECURITY
  - [ ] ✗ USE_SECRETS_MANAGER (disabled - using Jenkins credentials)
  - [ ] ✓ INSTALL_POLICIES
- [ ] Click "Build"
- [ ] Monitor Console Output (refresh page)
- [ ] Wait ~45 minutes for completion

### Step 17: Verify Deployment
SSH into EC2 and run:
```bash
cd ~/YOUR_REPO
./ssddlabfinal/scripts/verify-security.sh
```
- [ ] All 11 security checks PASS

```bash
kubectl get pods -n voting-system
```
- [ ] All pods Running

```bash
kubectl get pods -n monitoring
```
- [ ] Prometheus, Grafana, Loki, Falco Running

```bash
curl http://localhost:8000/health
```
- [ ] Returns: {"status":"healthy"}

### Step 20: Access Application
Open browser and test:
- [ ] Backend API: `http://YOUR_ELASTIC_IP:8000`
- [ ] Frontend: `http://YOUR_ELASTIC_IP:5173`
- [ ] Grafana: `http://YOUR_ELASTIC_IP:3000` (admin/admin)
- [ ] Prometheus: `http://YOUR_ELASTIC_IP:9090`

---

## ☑️ PHASE 5: Testing (15 minutes)

### Step 21: Test Application Functionality
- [ ] Register new user (Frontend)
- [ ] Login with user
- [ ] Create election (if admin)
- [ ] Cast vote
- [ ] View election results
- [ ] Check backend metrics: `http://YOUR_ELASTIC_IP:8000/metrics`

### Step 22: Test Monitoring
- [ ] Grafana → Dashboards → Voting System Dashboard
- [ ] Verify panels showing data:
  - [ ] Total Votes
  - [ ] Total Users
  - [ ] Request Rate
  - [ ] Latency (p95)
  - [ ] Error Rate
  - [ ] Rate Limit Violations

### Step 23: Test Security Features
```bash
# SSH hardening
grep "^PasswordAuthentication" /etc/ssh/sshd_config
# Should show: PasswordAuthentication no

# Firewall
sudo ufw status
# Should show: Status: active

# Fail2Ban
sudo fail2ban-client status
# Should show jail running

# CloudWatch
sudo systemctl status amazon-cloudwatch-agent
# Should show: active (running)

# Secrets
kubectl get secret voting-secrets -n voting-system
# Should exist

# Policies
kubectl get clusterpolicy
kubectl get constrainttemplates
# Should list policies
```
- [ ] All security features active

---

## ☑️ PHASE 6: Ongoing Operations

### For Subsequent Deployments (after code changes)
- [ ] Make code changes
- [ ] `git add . && git commit -m "Update" && git push`
- [ ] GitHub webhook triggers Jenkins automatically
- [ ] OR manually: Jenkins → Build with Parameters
  - [ ] ☐ SETUP_SECURITY (already done)
  - [ ] ☐ USE_SECRETS_MANAGER (secrets exist)
  - [ ] ✓ DEPLOY_TO_K8S
  - [ ] ☐ INSTALL_MONITORING (already installed)
  - [ ] ☐ INSTALL_POLICIES (already installed)
- [ ] Duration: ~10 minutes

### Regular Maintenance
- [ ] Monitor CloudWatch Logs: AWS Console → CloudWatch
- [ ] Check Grafana dashboards weekly
- [ ] Review Fail2Ban banned IPs: `sudo fail2ban-client status sshd`
- [ ] Rotate secrets every 90 days (update Secrets Manager)
- [ ] Check disk space: `df -h`
- [ ] Review Jenkins build history

---

## 📊 Success Criteria

✅ **You're done when ALL of these work:**

1. [ ] SSH connection works with key-only (no password)
2. [ ] Jenkins pipeline runs without errors
3. [ ] `verify-security.sh` shows 11/11 PASS
4. [ ] All pods Running in `voting-system` namespace
5. [ ] All pods Running in `monitoring` namespace
6. [ ] Backend health check returns 200 OK
7. [ ] Frontend loads in browser
8. [ ] Can register, login, and vote
9. [ ] Grafana shows metrics
10. [ ] Prometheus scraping targets

---

## 🆘 Troubleshooting

### Issue: Jenkins can't run docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: Minikube not found by Jenkins
```bash
sudo cp /home/ubuntu/.kube/config /var/lib/jenkins/.kube/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube/
```

### Issue: Port forwarding not accessible
- [ ] Check security group allows ports
- [ ] Check UFW: `sudo ufw status`
- [ ] Check port forwarding logs: `cat /tmp/backend-portforward.log`

### Issue: Secrets Manager access denied
```bash
aws sts get-caller-identity  # Verify IAM role
```

### Issue: Pods not starting
```bash
kubectl describe pod <pod-name> -n voting-system
kubectl logs <pod-name> -n voting-system
```

---

## 📚 Reference Documents

- Detailed specs: `docs/AWS-EC2-SETUP.md`
- Step-by-step guide: `docs/MANUAL-SETUP-GUIDE.md`
- Automation details: `docs/SECURITY-AUTOMATION-GUIDE.md`
- Implementation summary: `docs/IMPLEMENTATION-SUMMARY.md`

---

**Estimated Total Time**: 2-3 hours (including waiting for installations)

**Cost**: ~$130/month (m7i.large + storage)

**Last Updated**: December 19, 2025
