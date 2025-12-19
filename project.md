Department of Computer Science & Engineering
CYC386 Secure Software Design & Development
Final Lab Project Guidelines
End-to-End Secure Cloud-Native DevSecOps Platform with Multi-Layer
Defense, Observability, and Infrastructure-as-Code
Instructor: Engr. Muhammad Ahmad Nawaz
Department of Computer Science
COMSATS University Islamabad
Semester: Fall 2025
Project Type: Lab Final Examination (Weeks 814)
Assigning Date: October 25, 2025
Course Description Form (CDF)
Course Information
Attribute
Details
Course Code
Course Title
Credit Hours
Lecture Hours/Week
Lab Hours/Week
Pre-Requisites
CYC386
Secure Software Design and Development
3(2,1)
2
3
None
Catalogue Description: Secure software concepts; System issues; System properties; Soft
ware Project Time Management; Software Project Costing; Software Quality Assurance; Se
curity Concepts in the SDLC; Risk management; Security standards; Best practices; Security
methodologies; Security frameworks; Regulations-Privacy and Compliance; Security Models;
Trusted Computing; Secure Software Requirements; Secure Software Design; Design Processes;
Secure Software Implementation/Coding; Software Development Methodologies; Common Soft
ware Vulnerabilities and Controls; Defensive Coding PracticesConcepts and Techniques; Code
Vulnerabilities and Avoiding Polymorphic Malware Attacks: Buffer overflow, Format string bug,
Code vulnerabilities SQL Injection, Cross-site Scripting, Cross-site Request Forgery, Session
management, Replication of vulnerabilities and exploitation; Secure Software Testing; Secu
rity Testing Methodologies; Software Security Testing; Software Acceptance; Legal Protection
Mechanisms; Software Deployment-Operations-Maintenance and Disposal.
Unit-wise Major Topics
1
CYC386 Secure Software Design & Development
2
Unit Topic
No.
of
Teaching
Hours
1
2
3
4
5
6
7
Secure Software: Overview, Properties, Issues,
System Properties; Secure SDLC; and Secure
Software Development Methodologies.
Requirement Analysis: Stakeholder Identifi
cation, Requirement Gathering, Functional &
Non-Functional Security, and Use-case Con
struction.
Secure Design Considerations: Security Perime
ter, Attack Surface, Application Security &
Resilience Principles, Mapping Best Practices;
(OWASP development guide, OWASP code re
view guide, OWASP testing guide Security
Design & Architecture); Risk Management:
Threats, and Application Risk Modeling.
Security frameworks, e.g., Zachman Framework,
Control Objectives for Information and Re
lated Technology, Sherwood Applied Business
Security Architecture (SABSA), Regulations
Privacy and Compliance; Security Models (e.g.,
BLP Confidentiality Model, Clark and Wilson
Model (Access Triple Model)); Trusted Com
puting; Secure Software Requirements (Sources
for Security Requirements, Types of Security
Requirements); Secure Software Design (Design
consideration, Information Technology Security
Principles and Secure Design, Designing Secure
Design Principles)
Code vulnerabilities SQL Injection, Cross-site
Scripting, Cross-site Request Forgery, Session
management, Replication of vulnerabilities and
exploitation
Testing: Static Analysis, Dynamic Analysis;
and Securing DevOps.
AppSec Process: Overview, Maturity Mod
els, Software Assurance Maturity Model; Fron
tiers for AppSec: Internet of Things (IoT),
Blockchain, Microservices & APIs, Containers,
Web Application Firewalls, Machine Learning,
Artificial Intelligence, and Big Data.
3
3
3
4
6
5
6
Total
Con
tact
Hours
30
Mapping of CLOs and GAs
CYC386 SecureSoftwareDesign&Development 3
Sr.#Unit
#
CourseLearningOutcomes Bloom’s
Taxonomy
Learning
Level
GA
CLOs
for
The
ory
CLO
1
1 Understand software security standards,
models,processes,andbestpracticesthat
need tobe incorporated throughout the
softwaredevelopmentlifecycle.
Understanding2
CLO
2
2-4 Applyresilientprinciples for secure soft
waredesignandimplementation.
Applying 2
CLO
3
5 Apply static anddynamic testing tech
niquestotestsoftwaresecurity.
Applying 2
CLO
4
6,7 Criticallyevaluatethethreatsandvulner
abilitiesassociatedwithinformation,com
putingandmanagementsystemsanduse
requiredsecurityprinciples.
Analyzing 2,3
CLOs
for
Lab
CLO
5
2-7 Analyzeandtestsoftwaretoidentifyvul
nerabilities,mitigate threats, andensure
securesolutions.
Applying 2,3
CLO
6
1-7 Developanattackresistantsoftware ina
teamenvironment
Creating 2-4,6
CLOAssessmentMechanism
Assessment
Tools
CLO
1
CLO
2
CLO
3
CLO
4
CLO
5
CLO
6
Quizzes Quiz
1
Quiz
2
Quiz
3
Quiz
4--
Assignments Assignment
1&2
Assignment
3
Assignment
4--
LabAssignments---- Lab
As
sign
ments
MidTermExam Mid
Term
Exam
Mid
Term
Exam
Mid
Term
Exam--
FinalTermExam Final
Term
Exam
Final
Term
Exam----
CYC386 Secure Software Design & Development
4
Assessment
Tools
CLO
1
CLO
2
CLO
3
CLO
4
CLO
5
CLO
6
Project----
Lab
Project
Text and Reference Books
Text Books:
1. Building Secure Software: A Hands-On Guide for Developers, Nikolai Lebedevz, 2024
2. Designing Secure Software: A Guide for Developers, Loren Kohnfelder, No Starch Press,
2021.
3. Secure, Resilient, and Agile Software Development, Mark S. Merkow, CISSP, CISM,
CSSLP, CRC Press, 2019.
4. Secure Software Design, Theodor Richardson, Charles N Thies, Jones & Bartlett Learning,
2012.
Reference Book:
1. Software Security: Building secure software applications, Neha Kaul, Arcler Press, 2019.
CYC386 Secure Software Design & Development
5
1 Introduction
This final lab project challenges student teams to design, develop, and defend a secure,
cloud-native application aligned with modern DevSecOps and Zero Trust principles. Stu
dents will implement security-by-design, container orchestration, and infrastructure
automation, culminating in a live security defense demonstration during the final lab
examination.
The project replicates the real-world Secure Software Development Lifecycle (SS
DLC) fromeliciting security requirements to deploying, hardening, and monitoring a production
ready system.
2 Project Duration & Team Structure
• Duration: 6 Weeks (Weeks 814)
• Maximum Team Size: 3 members
• Suggested Roles:
1. Lead Developer (Secure Coding & Authentication)
2. Security Analyst (Threat Modelling & Testing)
3. DevSecOps Engineer (Automation, Infrastructure & Monitoring)
3 Project Objectives
By the end of this project, students should be able to:
1. Architect secure, containerized, and distributed applications.
2. Apply OWASP ASVS and NIST CSF frameworks in software design.
3. Implement authentication, access control, and encryption mechanisms.
4. Automate security testing and infrastructure provisioning.
5. Deploy services securely using Kubernetes and Terraform.
6. Monitor runtime behavior and detect anomalies using Prometheus and Falco.
7. Present an end-to-end secure DevSecOps pipeline with live demonstration.
4 Project Scope and Technical Domains
Each project must include the following components:
Domain
Description
Secure Design & Architecture
Secure Coding
Containerization & Orchestration
Apply OWASP ASVS controls, define
trust boundaries, and model threats using
STRIDE/DREAD.
Implement input validation, encryption, authen
tication (OAuth2/JWT), and secure logging.
Package application using Docker and orches
trate with Kubernetes & Helm.
CYC386 SecureSoftwareDesign&Development 6
Domain Description
InfrastructureasCode(IaC) AutomateenvironmentprovisioningusingTer
raformandVaultforsecrets.
DevSecOps&CI/CD Automate builds, testing, and scanning us
ingGitHubActions, SonarQube, Trivy, and
OWASPZAP.
Monitoring&Observability IntegratePrometheus,Grafana,andLokidash
boardswithruntimedetectionusingFalco.
Compliance&Reporting Map controls toNISTCSF andCIS bench
marks;produceanexecutivesecurityreport.
5 WeeklyMilestonePlan(Weeks814)
Week Phase KeyActivities Tools /Frame
works
Deliverables
Week8 Phase 1
Security Re
quirements
& Threat
Modelling-Identify12+securityrequirements
(OWASP ASVS).<br>- Perform
STRIDE/DREAD analysis.<br>
Define 34 trust boundaries.<br>
DevelopRiskMatrix.
OWASP ASVS,
Threat Dragon,
Draw.io
Security Requirement
Document (SRD) +
ThreatModelDiagram
Week9 Phase 2 Se
cure Architec
tureDesign- Design microservice-based
architecture.<br>-Define
Zero Trust perimeters & IAM
roles.<br>- Create C4 and data
flowdiagrams.<br>-Mapsecurity
controlstoNISTCSF.
Lucidchart, C4
Model, OWASP
SAMM
Secure Architecture
Blueprint + NIST
Mapping
Week10 Phase 3
Secure Imple
mentation &
Testing- Implement APIs with authenti
cation (JWT/OAuth2).<br>- En
force validation, encryption, and
logging.<br>- Perform SAST &
DASTanalysis.<br>-Fixvulnera
bilitiesanddocument.
Python/Node.js
/ Java, Sonar
Qube, OWASP
ZAP,Snyk
SecureCodebase+Test
Reports
Week11 Phase4 Con
tainerization,
Orchestra
tion&Policy
Enforcement- Containerize services with
Docker.<br>- Deploy on Ku
bernetes using Helm.<br>
Apply OPA/Kyverno policy
enforcement.<br>- Conduct CIS
Docker/KubernetesBenchmarking.
Docker, Kuber
netes, Helm,
OPA/Kyverno,
Trivy
Dockerfiles, Helm
Charts, Compliance
Report
Week12 Phase 5 In
frastructureas
Code(IaC)- Provision infrastructure using
Terraform.<br>- Configure Vault
for secret management.<br>
Deploy multi-tier app on cloud
(AWS/Azure).<br>-Validate least
privilegeIAMpolicies.
Terraform,Vault,
AWS Edu
cate/Azure
Terraform Scripts +
CloudDiagram+Vault
Setup
CYC386 Secure Software Design & Development
7
Week
Phase
Key Activities
Tools / Frame
works
Deliverables
Week 13 Phase 6 De
vSecOps,
Monitoring
& Runtime
Security
Week 14 Phase 7 Fi
nal Defense &
Evaluation- Automate build, test, and de
ploy
pipelines.<br>-
Integrate
SonarQube, Trivy, and OWASP
ZAP.<br>- Configure Prometheus
& Grafana.<br>- Deploy Falco for
runtime intrusion detection.<br>
Simulate SOC alerting.
Perform
vulnerability
reassessment.<br>- Map mitiga
tions to NIST CSF functions.<br>
Prepare executive report and
presentation.<br>- Conduct live
defense and demo.
GitHub
tions,
Ac
Jenkins,
Prometheus,
Grafana, Falco,
Loki
All
tools
integrated
CI/CD Pipeline Config
+ Dashboards + Alert
Logs
Final Report + Presen
tation + Demo Video
6 Advanced Functional & Security Requirements
1. Authentication & Access Control: OAuth2.0 or JWT with RBAC and OPA policies.
2. Encryption: Data encryption in transit (TLS) and at rest (AES-256).
3. Policy-as-Code: Enforce Kubernetes security policies via Kyverno or OPA Gatekeeper.
4. Secrets Management: Centralize credentials using Vault or AWS KMS.
5. Infrastructure Compliance: Validate Terraform using Checkov or Terraform Compli
ance.
6. Container Security: Apply image scanning (Trivy), and CIS Docker/K8s benchmarks.
7. Monitoring & Logging: Prometheus for metrics, Grafana for visualization, Loki for
logs.
8. Runtime Threat Detection: Deploy Falco to monitor syscalls and detect container
anomalies.
9. Alerting: Integrate Alertmanager for email/Slack alert notifications.
10. Reporting: Generate SAST, DAST, IaC compliance, and runtime event reports.
7 Evaluation Rubric
Assessment Area
WeightEvaluation Criteria
Requirements & Threat Modelling 10%
Secure Design & Architecture
Secure Implementation
15%
20%
Completeness, ASVS alignment,
risk justification
Trust boundaries, Zero Trust, en
cryption strategy
Code quality, authentication, vul
nerability mitigation
CYC386 Secure Software Design & Development
8
Assessment Area
WeightEvaluation Criteria
Containerization & Policy Enforce
ment
Infrastructure as Code (IaC)
DevSecOps & Automation
Monitoring & Runtime Detection
Final Presentation & Documenta
tion
15%
10%
10%
10%
10%
Docker/Kubernetes security, OPA
policies, hardening
Terraform accuracy, Vault integra
tion, compliance
CI/CD pipeline, automated scans,
workflow integrity
Prometheus/Grafana metrics, Falco
alerts, SOC simulation
Professional report, clarity, live
demo, defense
8 Learning Outcomes (CLOs)
CLODescription
Performance Indicator
Blooms
Level
CLO
1
Apply secure software design and
risk analysis principles.
CLO
2
Implement security controls and se
cure coding standards.
CLO
3
Automate secure deployments and
infrastructure management.
CLO
4
Evaluate runtime security and sys
tem observability.
CLO
5
Present and defend a secure DevSec
Ops system.
Threat modelling and security
requirements
SAST/DAST, secure coding
practices
Terraform, Kubernetes, OPA
integration
Prometheus, Grafana, Falco
dashboards
Live demo, documentation,
Q&A
Apply
Demonstrate
Perform
Analyze
Present
9 Toolchain Summary
Category
Tools / Frameworks
Design & Threat Modelling
Coding & Testing
Containerization
Orchestration & Policy
Infrastructure as Code (IaC)
Automation (CI/CD)
Monitoring & Observability
Runtime Security
Compliance Tools
SIEM Simulation (Optional)
OWASP ASVS, Threat Dragon, Lucidchart, C4
Model
Python / Node.js / Java, SonarQube, OWASP
ZAP, Snyk
Docker, Docker Compose, Trivy
Kubernetes, Helm, OPA, Kyverno
Terraform, Vault, AWS Educate, Azure for Stu
dents
GitHub Actions, Jenkins
Prometheus, Grafana, Loki, Alertmanager
Falco
CIS Benchmarks, Checkov, Terraform Compli
ance
ELK Stack, Wazuh, Security Onion
CYC386 Secure Software Design & Development
9
10 Bonus Extensions (Up to +15%)
Extension Domain
Description
Bonus
AI-Assisted Security Analysis
Multi-Cloud Deployment
Threat Intelligence Integration
SOAR Workflow Simulation
Integrate an AI agent to review code or Ter
raform scripts for misconfigurations.
Deploy redundant Kubernetes clusters on both
AWS and Azure.
Integrate open threat feeds (MISP, OTX) into
Falco alerts.
Automate alert response using TheHive or
Wazuh.
+5%
+5%
+3%
+2%
11 Submission Structure
/docs
/src
/docker
/iac
/ci
/monitor
/reports
/README.md
SRD, Threat Model, Design, Reports
Source Code (Application)
Dockerfiles, Helm Charts, Kubernetes YAMLs
Terraform & IaC scripts
CI/CD Configurations
Prometheus, Grafana, Falco Setup
Compliance, Vulnerability & Test Reports
Project Overview, Roles, Setup Instructions
12 Deliverables Checklist
• Security Requirement Document (SRD)
• Threat Model Diagram & Risk Matrix
• Secure Architecture Blueprint
• Secure Source Code (with SAST/DAST reports)
• Docker & Kubernetes Deployment
• Terraform Infrastructure Scripts
• CI/CD Pipeline Configurations
• Monitoring & Runtime Security Setup
• Executive Report (NIST CSF Mapping)
• Presentation Slides + Demo Video
13 Reference Frameworks & Standards
• NIST SP 800-160 Vol. 1 Systems Security Engineering
• NIST Cybersecurity Framework (CSF)
• OWASP ASVS v5.0 and OWASP SAMM
CYC386 Secure Software Design & Development
10
• ISO/IEC 27034 Application Security
• CIS Docker & Kubernetes Benchmarks
• MITRE ATT&CK Enterprise Framework
• CSA Cloud Controls Matrix (CCM)
14 Evaluation Mode
• Type: Group-based, Continuous + Summative
• Submission: Through GitHub Classroom
• Defense: Live Demo and Oral Examination (Week 14)
• Weightage: 30% of Final Lab Grad