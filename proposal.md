COMSATS university
Islamabad
Project Title:
Secure Online Voting
System
Course: CYC386 – Secure Software Design & Development
Team Members & Roles:
1. Muhammad Saad Ullah (FA22-BCT-044)
2. Irfan Riaz (FA22-BCT-010)
3. Jawad Abbasi (FA22-BCT-012)
4. Shahab Ishaq khan (FA22-BCT-029)
Instructor: Engr. Muhammad Ahmad Nawaz
Semester: Fall 2025
 
1. Project Description
The Secure Online Voting System is a cloud-native platform that allows voters to register, authenticate, and cast votes securely. The system ensures the confidentiality, integrity, availability, and auditability of votes while supporting real-time monitoring of the election process.

The project demonstrates end-to-end secure software development using DevSecOps practices, including secure coding, containerization, infrastructure-as-code, CI/CD pipelines, and runtime monitoring.
2. Objectives
• Enable secure user registration and authentication.
• Implement role-based access control for voters and admins.
• Ensure encrypted storage and transmission of votes.
• Provide secure admin functionality for election management.
• Track and audit all critical system events.
• Containerize and deploy the application on Kubernetes.
• Automate CI/CD and security testing.
• Monitor system health and detect runtime anomalies.
3. Functionality:
Functionality Overview and Security Features
COMPONENT	FUNCTIONALITY	SECURITY FEATURES
USER REGISTRATION	Users can register with unique credentials	Input validation, password hashing (bcrypt), optional email verification
AUTHENTICATION	Login for voters/admin	OAuth2/JWT tokens
ROLE MANAGEMENT	Different roles: voter, election admin	RBAC enforced via JWT claims
ELECTION MANAGEMENT (ADMIN)	Admin can create/manage elections	Secure endpoints, logging
 
COMPONENT	FUNCTIONALITY	SECURITY FEATURES
VOTING PROCESS	Users can cast votes	AES-256 encryption, anti-replay protection
VOTE COUNTING	Tally votes securely	Integrity check (hash-based), audit logs
AUDIT LOGGING	Track system events	Centralized logging with Loki
WEB INTERFACE / API	Simple UI + REST API	CSRF/XSS protection, input validation
CONTAINERIZATION	Deployable with Docker/K8s	CIS benchmarks, basic policy enforcement
INFRASTRUCTURE	Deployable via IaC	Terraform scripts, secrets stored in Vault
CI/CD & TESTING	Automated testing & deployment	SAST (SonarQube), DAST (OWASP ZAP), Trivy scans
MONITORING & ALERTING	Runtime monitoring of services	Prometheus metrics, Grafana dashboards, Falco alerts
4. Security Requirements
• Authentication & Access Control: OAuth2/JWT, RBAC
• Encryption: TLS 1.2+ for traffic, AES-256 for votes at rest
• Input Validation: Prevent SQL Injection, XSS, CSRF; server-side validation
• Policy Enforcement (K8s/IaC): PodSecurity, NetworkPolicies, OPA/Kyverno
• Secrets Management: Vault or AWS KMS for credentials and JWT secrets
• Logging & Monitoring: Audit logs, Prometheus + Grafana dashboards, Falco for runtime threat detection
• CI/CD Pipeline: Automated SAST/DAST scans, Trivy container scans, deployment to Kubernetes
5. Tools & Technology Stack
• Frontend & Backend: Python/Node.js/Java (minimal APIs)
• Database: PostgreSQL/MySQL (encrypted storage)
• Containerization: Docker, Kubernetes
• IaC & Secrets: Terraform, Vault
• CI/CD: GitHub Actions / Jenkins
• Security & Testing: SonarQube, OWASP ZAP, Trivy
• Monitoring: Prometheus, Grafana, Falco
 
6. Deliverables
• Source code with secure implementation
• Dockerfiles & Kubernetes deployment
• Terraform scripts & Vault configuration
• SAST & DAST test reports
• Prometheus/Grafana monitoring dashboards
• Audit log records
• Final report and presentation for demonstration
7. Timeline (6 Weeks)
Project Timeline
WEEK	TASK
1	Security requirements & threat modeling
2	Architecture design & role definitions
3	Backend & frontend MVP implementation
4	Containerization & Kubernetes deployment
5	CI/CD integration, testing, monitoring setup
6	Final testing, report preparation, and demo

