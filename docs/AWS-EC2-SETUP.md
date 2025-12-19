# AWS EC2 Infrastructure Setup - Secure Voting System

## Instance Specifications

### EC2 Instance Configuration
- **Instance Type**: m7i.large (note: not covered by free tier)
  - vCPUs: 2
  - Memory: 8 GiB
  - Network Performance: Up to 12.5 Gbps
  - EBS-Optimized: Yes
- **AMI**: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  - AMI ID: ami-0c7217cdde317cfec (us-east-1) - verify latest in your region
- **Architecture**: x86_64

### Storage Configuration

#### Root Volume
- **Volume Type**: gp3 (General Purpose SSD)
- **Size**: 80 GB (includes OS, Docker images, Jenkins workspace, K8s volumes)
- **IOPS**: 3000 (baseline for gp3)
- **Throughput**: 125 MB/s (baseline for gp3)
- **Encryption**: Enabled (AWS KMS default key)
- **Delete on Termination**: No (for data persistence)

**Total Storage**: 80 GB (single volume)

### Networking Configuration

#### VPC Setup
```
VPC CIDR: 10.0.0.0/16
VPC Name: voting-system-vpc

Subnets:
├── Public Subnet 1 (us-east-1a): 10.0.1.0/24
│   └── Purpose: Jenkins/K8s control plane
└── Public Subnet 2 (us-east-1b): 10.0.2.0/24
    └── Purpose: High availability (future)

Internet Gateway: voting-igw (attached to VPC)
Route Table: Public routes (0.0.0.0/0 → igw)
```

#### Network Interface
- **Primary Private IP**: Auto-assign from subnet (e.g., 10.0.1.50)
- **Elastic IP**: Allocate and associate (for persistent public access)
  - Purpose: Stable IP for Jenkins webhook, SSH access
- **DNS Hostnames**: Enabled
- **Source/Destination Check**: Enabled

#### Ports & Protocols Summary
| Service | Port | Protocol | Source | Purpose |
|---------|------|----------|--------|---------|
| SSH | 22 | TCP | Your IP/CIDR | Remote access |
| HTTP | 80 | TCP | 0.0.0.0/0 | Frontend access |
| HTTPS | 443 | TCP | 0.0.0.0/0 | Secure frontend |
| Jenkins UI | 8080 | TCP | Your IP/CIDR | CI/CD dashboard |
| Jenkins Agents | 50000 | TCP | 10.0.0.0/16 | Agent communication |
| Kubernetes API | 6443 | TCP | 10.0.0.0/16 | K8s control plane |
| Backend API | 8000 | TCP | 10.0.0.0/16 | Voting backend |
| Frontend | 5173 | TCP | 0.0.0.0/0 | Dev frontend |
| Grafana | 3000 | TCP | Your IP/CIDR | Monitoring dashboard |
| Prometheus | 9090 | TCP | 10.0.0.0/16 | Metrics collection |
| NodePort Range | 30000-32767 | TCP | 0.0.0.0/0 | K8s services |

## Security Groups Configuration

### Security Group 1: voting-jenkins-k8s-sg

**Description**: Primary security group for Jenkins and Kubernetes cluster

#### Inbound Rules

```yaml
# SSH Access (restricted to your IP)
- Type: SSH
  Protocol: TCP
  Port: 22
  Source: YOUR_IP_ADDRESS/32
  Description: SSH access from admin workstation

# HTTP (for frontend/ALB)
- Type: HTTP
  Protocol: TCP
  Port: 80
  Source: 0.0.0.0/0
  Description: Public HTTP access

# HTTPS (for secure frontend)
- Type: HTTPS
  Protocol: TCP
  Port: 443
  Source: 0.0.0.0/0
  Description: Public HTTPS access

# Jenkins UI (restricted)
- Type: Custom TCP
  Protocol: TCP
  Port: 8080
  Source: YOUR_IP_ADDRESS/32
  Description: Jenkins web interface

# Jenkins Agent Communication
- Type: Custom TCP
  Protocol: TCP
  Port: 50000
  Source: 10.0.0.0/16
  Description: Jenkins master-agent communication

# Kubernetes API Server
- Type: Custom TCP
  Protocol: TCP
  Port: 6443
  Source: 10.0.0.0/16
  Description: Kubernetes API server

# Backend API (internal)
- Type: Custom TCP
  Protocol: TCP
  Port: 8000
  Source: 10.0.0.0/16
  Description: Voting backend API

# Frontend Dev Server
- Type: Custom TCP
  Protocol: TCP
  Port: 5173
  Source: 0.0.0.0/0
  Description: Vite dev server (development only)

# Grafana Dashboard (restricted)
- Type: Custom TCP
  Protocol: TCP
  Port: 3000
  Source: YOUR_IP_ADDRESS/32
  Description: Grafana monitoring dashboard

# Prometheus (internal)
- Type: Custom TCP
  Protocol: TCP
  Port: 9090
  Source: 10.0.0.0/16
  Description: Prometheus metrics server

# Kubernetes NodePort Services
- Type: Custom TCP
  Protocol: TCP
  Port Range: 30000-32767
  Source: 0.0.0.0/0
  Description: Kubernetes NodePort services

# Minikube/Docker communication
- Type: All TCP
  Protocol: TCP
  Port Range: 0-65535
  Source: sg-xxxxxxxx (self-reference)
  Description: Allow all internal communication

# Ping/ICMP (optional, for troubleshooting)
- Type: All ICMP - IPv4
  Protocol: ICMP
  Port: All
  Source: 10.0.0.0/16
  Description: Internal network diagnostics
```

#### Outbound Rules

```yaml
# Allow all outbound traffic (default)
- Type: All traffic
  Protocol: All
  Port Range: All
  Destination: 0.0.0.0/0
  Description: Allow all outbound traffic
```

### Security Group 2: voting-database-sg (Future - for RDS)

**Description**: Database security group for PostgreSQL RDS (when migrating from local)

#### Inbound Rules

```yaml
# PostgreSQL from application
- Type: PostgreSQL
  Protocol: TCP
  Port: 5432
  Source: sg-xxxxxxxx (voting-jenkins-k8s-sg)
  Description: PostgreSQL access from K8s pods
```

## IAM Role Configuration

### EC2 Instance Role: voting-ec2-instance-role

**Trust Policy** (allows EC2 to assume role):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Attached Policies**:

1. **ECR Full Access** (for Docker image push/pull)
   - Policy: `arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess`

2. **CloudWatch Logs** (for logging)
   - Policy: `arn:aws:iam::aws:policy/CloudWatchLogsFullAccess`

3. **Custom Policy: VotingSystemEC2Policy**
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
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:voting/*"
    },
    {
      "Sid": "S3BackupAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::voting-system-backups",
        "arn:aws:s3:::voting-system-backups/*"
      ]
    }
  ]
}
```

## Key Pair Configuration

### SSH Key Pair
- **Key Name**: voting-system-key
- **Key Type**: RSA
- **Format**: .pem
- **Storage**: Secure local storage (never commit to git)
- **Permissions**: `chmod 400 voting-system-key.pem`

**SSH Connection Command**:
```bash
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP
```

## Instance Metadata Options (Security Hardening)

```yaml
HTTP tokens: required (IMDSv2 only)
HTTP PUT response hop limit: 1
Instance metadata service: Enabled
```

## Tags (for Resource Management)

```yaml
Name: voting-jenkins-k8s-server
Project: secure-voting-system
Environment: production
ManagedBy: manual
Owner: your-name
CostCenter: education
Backup: daily
```

## Monitoring & Logging

### CloudWatch Metrics (Enabled)
- Detailed Monitoring: Enabled (1-minute intervals)
- Metrics Collected:
  - CPUUtilization
  - NetworkIn/NetworkOut
  - DiskReadBytes/DiskWriteBytes
  - StatusCheckFailed

### CloudWatch Logs Agent (to be configured)
- Log Groups:
  - `/aws/ec2/voting-system/jenkins`
  - `/aws/ec2/voting-system/kubernetes`
  - `/aws/ec2/voting-system/application`

## Cost Estimation

### Monthly Costs (Approximate)

| Resource | Specification | Monthly Cost (USD) |
|----------|---------------|-------------------|
| EC2 m7i.large | On-Demand (24/7) | ~$124.10 |
| EBS gp3 (80 GB) | Root volume | ~$6.40 |
| Elastic IP | 1 address (associated) | Free |
| Data Transfer Out | First 100 GB | Free, then $0.09/GB |
| CloudWatch Logs | First 5 GB | Free, then $0.50/GB |
| **Total** | | **~$130.50/month** |

**Cost Optimization Tips**:
- Use t3.xlarge (cheaper, ~$123/month) if m7i.large not needed
- Stop instance when not in use (pay only for storage)
- Use Spot Instances for dev/testing (up to 90% savings)
- AWS Free Tier covers: 750 hours/month of t2.micro/t3.micro (not m7i.large)

## Security Hardening Checklist

### Pre-Launch Security
- [ ] Enable EBS encryption on all volumes
- [ ] Use IMDSv2 (require tokens)
- [ ] Restrict SSH to your IP only
- [ ] Enable VPC Flow Logs (optional)
- [ ] Enable CloudTrail for audit logging (optional)

### Post-Launch Security
- [ ] Update system: `sudo apt update && sudo apt upgrade -y`
- [ ] Configure UFW firewall (in addition to Security Groups)
- [ ] Install fail2ban for SSH brute-force protection
- [ ] Set up automatic security updates
- [ ] Disable password authentication (SSH keys only)
- [ ] Configure sudo without password for specific commands (optional)
- [ ] Install and configure auditd for system auditing
- [ ] Set up log rotation

## Network Architecture Diagram

```
                                    Internet
                                        │
                                        │
                                   [Internet Gateway]
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                    [Elastic IP]                  [Route Table]
                         │                             │
                         │                             │
                    ┌────┴─────────────────────────────┴────┐
                    │         VPC (10.0.0.0/16)             │
                    │                                        │
                    │  ┌──────────────────────────────┐     │
                    │  │   Public Subnet (10.0.1.0/24) │    │
                    │  │                               │     │
                    │  │  ┌─────────────────────┐     │     │
                    │  │  │   EC2 Instance      │     │     │
                    │  │  │   (10.0.1.50)       │     │     │
                    │  │  │                     │     │     │
                    │  │  │  ┌──────────────┐  │     │     │
                    │  │  │  │   Jenkins    │  │     │     │
                    │  │  │  │   :8080      │  │     │     │
                    │  │  │  └──────────────┘  │     │     │
                    │  │  │                     │     │     │
                    │  │  │  ┌──────────────┐  │     │     │
                    │  │  │  │  Minikube    │  │     │     │
                    │  │  │  │  K8s Cluster │  │     │     │
                    │  │  │  └──────────────┘  │     │     │
                    │  │  │                     │     │     │
                    │  │  │  ┌──────────────┐  │     │     │
                    │  │  │  │  Voting App  │  │     │     │
                    │  │  │  │  Pods        │  │     │     │
                    │  │  │  └──────────────┘  │     │     │
                    │  │  └─────────────────────┘     │     │
                    │  └──────────────────────────────┘     │
                    └───────────────────────────────────────┘

Security Groups:
├── voting-jenkins-k8s-sg (ports: 22, 80, 443, 8080, 6443, etc.)
└── Inbound: Restricted by IP/CIDR
```

## DNS Configuration (Optional)

If you have a domain:
1. Create Route 53 Hosted Zone
2. Add A Record pointing to Elastic IP
3. Configure SSL/TLS certificate via Let's Encrypt

```bash
# Example DNS records
voting.yourdomain.com    A     YOUR_ELASTIC_IP
jenkins.yourdomain.com   A     YOUR_ELASTIC_IP
grafana.yourdomain.com   A     YOUR_ELASTIC_IP
```

## Backup Strategy

### Automated Backups
- **EBS Snapshots**: Daily at 2 AM UTC
  - Retention: 7 days
  - Automated via AWS Backup or Lambda
- **Configuration Backup**: Store in S3
  - Jenkins config (`/var/lib/jenkins`)
  - Kubernetes manifests
  - Application secrets (encrypted)

### Manual Backup Commands
```bash
# Create EBS snapshot via AWS CLI
aws ec2 create-snapshot \
  --volume-id vol-xxxxxxxxx \
  --description "Manual backup $(date +%Y%m%d)"

# Backup Jenkins home
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins
aws s3 cp jenkins-backup-*.tar.gz s3://voting-system-backups/jenkins/
```

## Disaster Recovery Plan

### RTO (Recovery Time Objective): 1 hour
### RPO (Recovery Point Objective): 24 hours

**Recovery Steps**:
1. Launch new EC2 instance from latest AMI
2. Attach data volume from latest EBS snapshot
3. Restore Jenkins configuration from S3
4. Redeploy Kubernetes cluster and applications
5. Update DNS (if using Route 53)
6. Validate application functionality

## Compliance & Audit

### AWS Config Rules (Optional)
- `encrypted-volumes`: Ensure all EBS volumes are encrypted
- `ec2-instance-managed-by-ssm`: EC2 instances managed by Systems Manager
- `restricted-ssh`: SSH restricted to specific CIDR ranges

### CloudTrail Logging
Enable CloudTrail to log all API calls:
- S3 Bucket: `voting-system-cloudtrail-logs`
- Log file validation: Enabled
- Multi-region: Enabled

## Resource Naming Convention

```
Format: [project]-[environment]-[resource]-[identifier]

Examples:
- VPC: voting-prod-vpc
- Subnet: voting-prod-public-subnet-1a
- Security Group: voting-prod-jenkins-sg
- IAM Role: voting-prod-ec2-role
- EBS Volume: voting-prod-data-vol
- Elastic IP: voting-prod-eip
```

## Next Steps After Instance Launch

1. **Connect via SSH**: Use .pem key to access instance
2. **System Update**: Run full system upgrade
3. **Install Dependencies**: Docker, Kubernetes, Minikube, Jenkins
4. **Configure Firewall**: Set up UFW rules
5. **Mount Data Volume**: Format and mount /data volume
6. **Clone Repository**: Pull voting system code
7. **Run Initial Deployment**: Execute Jenkins pipeline
8. **Configure Monitoring**: Install CloudWatch agent
9. **Set Up Backups**: Configure automated EBS snapshots
10. **Security Hardening**: Apply security checklist items

---

## Quick Launch Summary

**AWS Console Steps**:
1. Navigate to EC2 → Launch Instance
2. Select Ubuntu 22.04 LTS AMI
3. Choose m7i.large instance type
4. Configure network: Select/create VPC and public subnet
5. Add storage: 30 GB root + 50 GB data (both gp3, encrypted)
6. Add tags as specified above
7. Create/select security group with rules above
8. Review and launch with voting-system-key.pem
9. Allocate and associate Elastic IP
10. Attach IAM role: voting-ec2-instance-role

**First SSH Commands**:
```bash
ssh -i voting-system-key.pem ubuntu@YOUR_ELASTIC_IP
sudo apt update && sudo apt upgrade -y
sudo reboot
```

---

**Document Version**: 1.0  
**Last Updated**: December 19, 2025  
**Author**: DevSecOps Team  
**Classification**: Internal Use
