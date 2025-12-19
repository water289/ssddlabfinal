# AWS Deployment Architecture

## Overview
This document outlines the AWS architecture for deploying the Secure Voting System with Jenkins CI/CD.

## Infrastructure Components

### 1. Compute & Orchestration
- **EKS Cluster**: Managed Kubernetes cluster (v1.28+)
  - Node Group: t3.medium instances (2-4 nodes)
  - VPC with public/private subnets across 2 AZs
  - Security groups for node-to-node and pod-to-pod communication
  
- **EC2 Instance**: Jenkins CI/CD server
  - Instance type: t3.large
  - Security group: Allow 8080 (Jenkins UI), 22 (SSH), 50000 (agent)
  - IAM role with EKS/ECR permissions

### 2. Database
- **RDS PostgreSQL**: 
  - Instance class: db.t3.small
  - Multi-AZ deployment: No (dev), Yes (prod)
  - Encryption at rest: AES-256
  - Backup retention: 7 days

### 3. Container Registry
- **ECR**: Private Docker registry
  - Repositories: `secure-voting-backend`, `secure-voting-frontend`
  - Image scanning: Enabled (Trivy integration)
  - Lifecycle policy: Keep last 10 images

### 4. Secrets Management
- **AWS Secrets Manager**:
  - JWT secret key
  - Database credentials
  - Vote encryption key (AES-256)
  - Rotation: Manual (dev), Automatic (prod)

### 5. Networking
- **VPC**: 10.0.0.0/16
  - Public subnets: 10.0.1.0/24, 10.0.2.0/24
  - Private subnets: 10.0.10.0/24, 10.0.11.0/24
- **ALB**: Application Load Balancer for ingress
  - HTTPS termination with ACM certificate
  - Target groups: backend (8000), frontend (80)
- **NAT Gateway**: For private subnet internet access

### 6. Monitoring & Logging
- **CloudWatch**:
  - Container logs from EKS
  - RDS metrics
  - ALB access logs
- **Prometheus/Grafana**: In-cluster monitoring
- **Falco**: Runtime security monitoring

## Jenkins Pipeline Flow

```
GitHub Webhook → Jenkins EC2
    ↓
Code Fetch & Test (backend/frontend)
    ↓
Docker Build (backend/frontend images)
    ↓
Push to ECR
    ↓
Helm Deploy to EKS
    ↓
Install/Update Monitoring Stack (optional)
    ↓
Port Forward Services (optional)
```

## Security Architecture

### Network Segmentation
- Frontend pods: Public subnet (via ALB)
- Backend pods: Private subnet (internal only)
- Database: Private subnet (no internet)
- NetworkPolicy: Pod-to-pod restrictions within cluster

### Identity & Access
- **IAM Roles**:
  - Jenkins EC2: EKS admin, ECR push/pull, Secrets Manager read
  - EKS Node Group: ECR pull, CloudWatch logs
  - Backend pods: Secrets Manager read (via IRSA)
- **RBAC**: Kubernetes ServiceAccounts with least privilege

### Encryption
- In transit: TLS 1.3 (ALB → pods, pods → RDS)
- At rest: AES-256 (RDS, EBS volumes, votes in DB)

### Policy Enforcement
- Kyverno: Pod security policies
- OPA Gatekeeper: Admission control
- AWS Security Groups: Network-level firewalls

## Terraform Structure (to be implemented)

```
iac/terraform/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── ecr/
│   ├── jenkins-ec2/
│   └── secrets-manager/
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── provider.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── prod/
```

## Deployment Checklist

### Pre-Deployment
- [ ] Configure AWS credentials in Jenkins
- [ ] Create ECR repositories
- [ ] Provision VPC and subnets
- [ ] Deploy EKS cluster
- [ ] Create RDS instance
- [ ] Store secrets in Secrets Manager
- [ ] Configure ALB with ACM certificate
- [ ] Set up Jenkins EC2 with kubectl/helm/docker

### Deployment
- [ ] Configure Jenkins credentials (dockerhub-creds, aws-creds)
- [ ] Set up GitHub webhook to Jenkins
- [ ] Run initial Jenkins build with DEPLOY_TO_K8S=true
- [ ] Verify pods are running: `kubectl get pods -n secure-voting`
- [ ] Install Kyverno: `kubectl apply -f policies/`
- [ ] Install Gatekeeper: `kubectl apply -f policies/gatekeeper/`
- [ ] Deploy monitoring: `helm install prometheus ...`
- [ ] Configure Grafana dashboards and alerts

### Post-Deployment
- [ ] Run CIS benchmark: `kubectl apply -f kube-bench.yaml`
- [ ] Execute OWASP ZAP scan against ALB endpoint
- [ ] Verify Falco runtime alerts
- [ ] Test vote encryption/decryption
- [ ] Validate JWT auth flows
- [ ] Check Prometheus metrics and Grafana dashboards
- [ ] Generate compliance reports (SAST/DAST/IaC)

## Cost Estimation (Monthly)

| Resource | Type | Quantity | Cost (USD) |
|----------|------|----------|------------|
| EKS Cluster | Control Plane | 1 | $73 |
| EC2 Nodes | t3.medium | 3 | ~$75 |
| RDS PostgreSQL | db.t3.small | 1 | ~$30 |
| Jenkins EC2 | t3.large | 1 | ~$60 |
| ALB | Standard | 1 | ~$20 |
| NAT Gateway | Standard | 1 | ~$35 |
| ECR Storage | <50GB | - | ~$5 |
| Secrets Manager | <10 secrets | - | ~$5 |
| **Total** | | | **~$303** |

*Note: Actual costs vary based on usage, data transfer, and storage.*

## Disaster Recovery

- **RDS Snapshots**: Automated daily backups
- **Helm Releases**: Stored in S3 backend
- **Container Images**: Retained in ECR (10 versions)
- **RTO**: < 1 hour (restore RDS + redeploy pods)
- **RPO**: < 24 hours (last DB snapshot)

## Scaling Strategy

- **HPA**: Backend scales 2-5 pods based on CPU (60% threshold)
- **Node Autoscaling**: Cluster Autoscaler for node provisioning
- **Database**: Vertical scaling (upgrade instance class) or read replicas
