# Manual Setup Guide - AWS EC2 Deployment

This document lists all tasks that **MUST be done manually** before running the Jenkins pipeline. The Jenkinsfile automates most security features, but some require AWS Console or one-time manual configuration.

---

## 🔴 PHASE 1: PRE-LAUNCH (AWS Console)

### 1.1 Create Security Group

**Cannot be automated** - Must be done in AWS Console before instance launch.

```
Steps:
1. AWS Console → IAM → Roles → Create role
2. Select "AWS service" → "EC2"
3. Attach these managed policies:
   ✓ AmazonEC2ContainerRegistryFullAccess
   ✓ CloudWatchLogsFullAccess
   
4. Click "Create policy" → JSON → Paste this custom policy:
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Operations",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:voting/*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/ec2/voting-system/*"
    }
  ]
}
```

```
5. Name policy: VotingSystemEC2Policy
6. Back to role creation → Attach VotingSystemEC2Policy
7. Role name: voting-ec2-instance-role
8. Create role ✓
```

### 1.2 Launch EC2 Instance

**Cannot be automated** - Must be done in AWS Console.

```
Steps:
1. EC2 → Launch Instance

2. Name: voting-jenkins-k8s-server

3. AMI: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   - Verify latest AMI in your region

4. Instance type: m7i.large
   - WARNING: Not free tier eligible (~$130/month)

5. Key pair: 
   - Create new key pair
   - Name: voting-system-key
   - Type: RSA
   - Format: .pem
   - Download and save securely ✓

6. Network settings:
   - VPC: Create new OR use existing
   - Subnet: Public subnet with auto-assign IP
   - Auto-assign public IP: Enable ✓
   - Firewall: Create security group (see section 1.3)

7. Configure storage:
   Root volume:
   - Size: 30 GB
   - Type: gp3
   - IOPS: 3000
   - Throughput: 125 MB/s
   - Encrypted: YES ✓
   - KMS key: (default) aws/ebs
   
   Click "Add new volume":
   - Device: /dev/sdf
   - Size: 50 GB
   - Type: gp3
   - Encrypted: YES ✓
   - Delete on termination: NO

8. Advanced details:
   - Metadata accessible: Enabled
   - Metadata version: V2 only (token required) ✓
   - Metadata response hop limit: 1

9. Launch instance ✓
```

### 1.3 Create Security Group

**Cannot be automated** - Must be done during instance launch or separately.

```
Name: voting-jenkins-k8s-sg
Description: Security group for Jenkins and Kubernetes cluster

Inbound rules (click "Add rule" for each):

Rule 1: SSH
- Type: SSH
- Protocol: TCP
- Port: 22
- Source: My IP (will show YOUR_IP/32)
- Description: SSH access

Rule 2-3: HTTP/HTTPS
- Type: HTTP, Protocol: TCP, Port: 80, Source: 0.0.0.0/0
- Type: HTTPS, Protocol: TCP, Port: 443, Source: 0.0.0.0/0

Rule 4: Jenkins
- Type: Custom TCP
- Port: 8080
- Source: My IP
- Description: Jenkins UI

Rule 5-8: Application ports
- Port 8000, Source: 0.0.0.0/0, Description: Backend API
- Port 5173, Source: 0.0.0.0/0, Description: Frontend
- Port 3000, Source: My IP, Description: Grafana
- Port 9090, Source: My IP, Description: Prometheus

Rule 9: Kubernetes NodePort
- Type: Custom TCP
- Port range: 30000-32767
- Source: 0.0.0.0/0
- Description: K8s NodePort

Rule 10: Internal VPC
- Type: All TCP
- Port range: 0-65535
- Source: Custom 10.0.0.0/16
- Description: Internal VPC

Rule 11: Self-reference
- Type: All traffic
- Source: Custom (select THIS security group ID)
- Description: Internal pod communication
```

### 1.4 Allocate Elastic IP

**Cannot be automated** - Must be done after instance launch.

```
Steps:
1. EC2 → Elastic IPs → Allocate Elastic IP address
2. Click "Allocate"
3. Select the new IP → Actions → Associate Elastic IP address
4. Instance: Select your voting-jenkins-k8s-server
5. Associate ✓

IMPORTANT: Save this IP address! You'll need it for:
- SSH connection
- GitHub webhook configuration
- DNS records (if using custom domain)
```

### 1.5 Verify Storage

**Quick verification** - Check root volume size.

```bash
# SSH into instance
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP

# Check root volume size
df -h /
# Should show approximately 80GB total

# List block devices
lsblk
# Should show single root volume (nvme0n1)
```

---

## 🟡 PHASE 2: POST-LAUNCH (One-Time Setup)

### 2.1 Initial System Update

**Must be done manually** - Run immediately after first SSH login.

```bash
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Reboot to apply kernel updates
sudo reboot

# Wait 1 minute, then reconnect
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP
```

### 2.3 Install Docker

**Must be done manually** - Jenkins requires Docker to be pre-installed.

```bash
# Install Docker dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker ps

# IMPORTANT: Logout and login again for group membership
exit
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP

# Test docker without sudo
docker ps
```

### 2.4 Install Minikube

**Must be done manually** - Kubernetes cluster for local deployment.

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version

# Start Minikube cluster (using Docker driver)
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g

# Verify cluster
kubectl get nodes
kubectl cluster-info

# Enable addons
minikube addons enable metrics-server
minikube addons enable ingress

# Configure kubectl context
kubectl config use-context minikube

# Verify
kubectl get pods -A
```

### 2.5 Install Jenkins

**Must be done manually** - CI/CD orchestration.

```bash
# Install Java (Jenkins requirement)
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-17-jre

# Verify Java
java -version

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check status
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# SAVE THIS PASSWORD!

# Add jenkins user to docker group (for pipeline)
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Wait 2 minutes for Jenkins to start
echo "Access Jenkins at: http://YOUR_ELASTIC_IP:8080"
```

### 2.6 Configure Jenkins

**Must be done manually** - Web UI configuration.

```
Steps:
1. Open browser: http://YOUR_ELASTIC_IP:8080

2. Paste initial admin password from step 2.5

3. Install suggested plugins (wait 5-10 minutes)

4. Create admin user:
   - Username: admin
   - Password: whoami@009 (or your preference)
   - Email: your-email@example.com

5. Jenkins URL: http://YOUR_ELASTIC_IP:8080
   - Click "Save and Finish"

6. Install additional plugins:
   - Manage Jenkins → Plugins → Available plugins
   - Search and install:
     ✓ Docker Pipeline
     ✓ Kubernetes CLI
     ✓ Credentials Binding
     ✓ GitHub Integration
   - Restart Jenkins

7. Configure Global Tools:
   - Manage Jenkins → Tools
   - Add Docker: Name=docker, Install automatically ✓
   - Add kubectl: Download from kubernetes.io
   - Save

8. Add Credentials:
   - Manage Jenkins → Credentials → System → Global credentials
   
   Credential 1: DockerHub
   - Kind: Username with password
   - Username: water289 (your DockerHub username)
   - Password: <your DockerHub token>
   - ID: dockerhub-creds
   - Description: DockerHub credentials
   - Create ✓
   
   Credential 2: Backend Secret Key
   - Kind: Secret text
   - Secret: <from Secrets Manager or generate new>
   - ID: secure-voting-secret-key
   - Description: JWT secret key
   - Create ✓
   
   Credential 3: Postgres Password
   - Kind: Secret text
   - Secret: <from Secrets Manager or generate new>
   - ID: secure-voting-postgres-password
   - Description: PostgreSQL password
   - Create ✓
```

### 2.7 Create Jenkins Pipeline Job

**Must be done manually** - Create the pipeline that will run Jenkinsfile.

```
Steps:
1. Jenkins Dashboard → New Item

2. Item name: secure-voting-pipeline
   Type: Pipeline
   Click OK

3. General:
   ✓ GitHub project: https://github.com/YOUR_USERNAME/YOUR_REPO

4. Build Triggers:
   ✓ GitHub hook trigger for GITScm polling

5. Pipeline:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/YOUR_USERNAME/YOUR_REPO
   - Branch: */main
   - Script Path: Jenkinsfile
   - Save ✓

6. Run first build manually:
   - Click "Build with Parameters"
   - Check all boxes for first run:
     ✓ SETUP_SECURITY: true
     ✓ USE_SECRETS_MANAGER: true
     ✓ DEPLOY_TO_K8S: true
     ✓ INSTALL_MONITORING: true
     ✓ INSTALL_POLICIES: true
   - Click "Build"
```

### 2.8 Configure GitHub Webhook

**Must be done manually** - For automatic builds on git push.

```
Steps:
1. GitHub → Your Repository → Settings → Webhooks → Add webhook

2. Payload URL: http://YOUR_ELASTIC_IP:8080/github-webhook/

3. Content type: application/json

4. Which events: Just the push event

5. Active: ✓

6. Add webhook ✓

7. Test webhook:
   - Click on webhook → Recent Deliveries
   - Should show green checkmark
```

---

## 🟢 PHASE 3: AUTOMATED BY JENKINS

The following are **fully automated** by the Jenkins pipeline:

✅ SSH hardening (password auth disabled)  
✅ UFW firewall configuration  
✅ Fail2Ban installation and configuration  
✅ Automatic security updates setup  
✅ CloudWatch Logs Agent installation  
✅ AWS Secrets Manager retrieval  
✅ Kubernetes secrets creation  
✅ Docker image building and scanning (Trivy)  
✅ Image push to DockerHub  
✅ Kyverno policy engine installation  
✅ OPA Gatekeeper installation  
✅ Policy enforcement (3 Kyverno + 3 Gatekeeper)  
✅ Helm chart deployment  
✅ Monitoring stack (Prometheus/Grafana/Loki/Falco)  
✅ Alert rules and Alertmanager config  
✅ Port forwarding setup  
✅ Security validation checks  

---

## 📋 VERIFICATION CHECKLIST

After completing all manual steps, run this verification:

```bash
# 1. Check IAM role
aws sts get-caller-identity
# Should show: arn:aws:sts::ACCOUNT:assumed-role/voting-ec2-instance-role/...

# 2. Check Docker
docker ps
# Should work without sudo

# 3. Check Minikube
kubectl get nodes
# Should show: minikube   Ready

# 4. Check Jenkins
curl http://localhost:8080
# Should return HTML

# 5. Check data volume
df -h /data
# Should show 50GB mounted

# 6. Check Secrets Manager access
aws secretsmanager list-secrets --region us-east-1
# Should list 4 secrets

# 7. Run security verification script
cd /path/to/repo
chmod +x ssddlabfinal/scripts/verify-security.sh
./ssddlabfinal/scripts/verify-security.sh
```

---

## 🎯 QUICK START COMMANDS

After all manual setup is complete:

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# Run Jenkins pipeline via UI
# OR trigger build via webhook:
git add .
git commit -m "Trigger pipeline"
git push origin main

# Monitor logs
# Jenkins: http://YOUR_ELASTIC_IP:8080/job/secure-voting-pipeline/lastBuild/console

# Once deployed, access application:
# Backend: http://YOUR_ELASTIC_IP:8000
# Frontend: http://YOUR_ELASTIC_IP:5173
# Grafana: http://YOUR_ELASTIC_IP:3000 (admin/admin)
```

---

## 🚨 TROUBLESHOOTING

### Issue: Jenkins can't run docker commands
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: Minikube not accessible from Jenkins
```bash
# Give Jenkins access to kubeconfig
sudo cp /home/ubuntu/.kube/config /var/lib/jenkins/.kube/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube/
```

### Issue: Secrets Manager access denied
```bash
# Verify IAM role attached
aws sts get-caller-identity

# Check IAM policy includes:
# secretsmanager:GetSecretValue on voting/* secrets
```

### Issue: Port forwarding not accessible externally
```bash
# Check security group allows ports 8000, 5173, 3000, 9090
# Verify UFW allows ports:
sudo ufw status numbered
```

### Issue: Disk space low
```bash
# Check disk usage
df -h /

# Clean Docker images
docker system prune -a

# Clean apt cache
sudo apt-get clean
```

---

## 📊 COST ESTIMATE

| Resource | Monthly Cost |
|----------|-------------|
| EC2 m7i.large (730 hrs) | $124.10 |
| EBS gp3 (80 GB) | $6.40 |
| Elastic IP (associated) | $0.00 |
| Data Transfer (100 GB) | $0.00 |
| CloudWatch Logs (5 GB) | $0.00 |
| Secrets Manager (4 secrets) | $1.60 |
| **Total** | **~$132/month** |

**To reduce costs:**
- Stop instance when not in use (pay only storage: ~$8/month)
- Use t3.xlarge instead (~$123/month, similar specs)
- Use Spot Instance for dev/test (up to 90% savings)

---

**Document Version**: 1.0  
**Last Updated**: December 19, 2025  
**Prerequisites**: AWS account, GitHub account, DockerHub account
