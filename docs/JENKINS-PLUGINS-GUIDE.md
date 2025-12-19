# Jenkins Testing & Reporting Plugins Guide

## 🎯 Complete Testing & Reporting Setup for SSDD Project

This guide shows ALL automated testing integrated into the Jenkins pipeline, aligned with:
- **OWASP ASVS v5.0** (Application Security Verification Standard)
- **NIST Cybersecurity Framework** 
- **CIS Benchmarks**
- **Project Requirements** (Week 10-13 deliverables)

---

## 📋 Complete Testing Matrix (12+ Security Scans)

| # | Test Type | Tool | Report Type | Project Requirement |
|---|-----------|------|-------------|-------------------|
| 1 | SAST - Python | **Bandit** | HTML | Week 10: Secure Implementation |
| 2 | Code Quality - Python | **Ruff** | HTML | Week 10: Code Quality |
| 3 | Code Quality - Frontend | **ESLint** | HTML | Week 10: Frontend Quality |
| 4 | Unit Testing | **PyTest** | HTML + JUnit XML | Week 10: Testing |
| 5 | Code Coverage | **Coverage.py** | HTML + Cobertura | Week 10: Coverage Analysis |
| 6 | Dependency Scan - Python | **Safety** | TXT | Week 10: SCA |
| 7 | Dependency Scan - NPM | **NPM Audit** | TXT | Week 10: SCA |
| 8 | Container Scan - Backend | **Trivy** | TXT + JSON | Week 11: Container Security |
| 9 | Container Scan - Frontend | **Trivy** | TXT + JSON | Week 11: Container Security |
| 10 | IaC Scan - Terraform | **Checkov** | TXT | Week 12: IaC Compliance |
| 11 | IaC Scan - Kubernetes | **Checkov** | TXT | Week 11: K8s Security |
| 12 | DAST | **OWASP ZAP** | HTML | Week 13: Dynamic Testing |
| 13 | SonarQube (Optional) | **SonarQube** | Dashboard | Week 13: Code Quality |
| 14 | Snyk (Optional) | **Snyk** | JSON | Week 10: Vulnerability Mgmt |

---

## Required Jenkins Plugins

### 1. **JUnit Plugin** (Built-in)
**Purpose**: Display test results and trends

**Features**:
- ✅ Test result visualization
- ✅ Trend graphs (pass/fail over time)
- ✅ Failure tracking
- ✅ Test duration metrics

**Configuration in Jenkinsfile**:
```groovy
junit allowEmptyResults: true, testResults: '**/test-results.xml'
```

**What you get**:
- Test Results dashboard on build page
- Historical test trend graphs
- Detailed failure reports with stack traces
- Test duration trends

---

### 2. **Code Coverage API Plugin**
**Purpose**: Visualize code coverage metrics

**Installation**:
```
Jenkins → Manage Jenkins → Plugins → Available
Search: "Code Coverage API"
```

**Configuration in Jenkinsfile**:
```groovy
publishCoverage adapters: [coberturaAdapter('coverage.xml')],
                sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
```

**Metrics provided**:
- Line coverage percentage
- Branch coverage
- Coverage trends over time
- File-level coverage details
- Coverage diff between builds

---

### 3. **HTML Publisher Plugin**
**Purpose**: Publish HTML reports (pytest, coverage, bandit)

**Installation**:
```
Jenkins → Manage Jenkins → Plugins → Available
Search: "HTML Publisher"
```

**Configuration in Jenkinsfile**:
```groovy
publishHTML([
  allowMissing: true,
  alwaysLinkToLastBuild: true,
  keepAll: true,
  reportDir: 'htmlcov',
  reportFiles: 'index.html',
  reportName: 'Code Coverage Report'
])
```

**Reports you can publish**:
- ✅ Coverage HTML reports (with line highlighting)
- ✅ PyTest HTML reports
- ✅ Security scan results
- ✅ Custom dashboards

---

### 4. **Warnings Next Generation Plugin**
**Purpose**: Parse and display static analysis warnings

**Installation**:
```
Jenkins → Manage Jenkins → Plugins → Available
Search: "Warnings Next Generation"
```

**Supported tools**:
- Ruff (Python linter)
- Bandit (Security scanner)
- ESLint (JavaScript)
- Trivy (Container scanning)

**Configuration in Jenkinsfile**:
```groovy
recordIssues(
  enabledForFailure: true,
  tool: pyLint(pattern: 'ruff-report.json', name: 'Ruff'),
  qualityGates: [[threshold: 50, type: 'TOTAL', unstable: true]]
)
```

**Features**:
- Issue trend graphs
- New vs fixed issues tracking
- Severity distribution
- File-level issue breakdown
- Quality gates (fail build if too many issues)

---

### 5. **Performance Plugin**
**Purpose**: Track performance metrics over time

**Installation**:
```
Jenkins → Manage Jenkins → Plugins → Available
Search: "Performance"
```

**Use case**: API response time testing

**Configuration**:
```groovy
perfReport sourceDataFiles: 'performance-results.xml'
```

---

### 6. **Dashboard View Plugin**
**Purpose**: Create custom dashboards

**Installation**:
```
Jenkins → Manage Jenkins → Plugins → Available
Search: "Dashboard View"
```

**Create dashboard**:
1. Jenkins → New View → Dashboard
2. Add portlets:
   - Test Result Trend
   - Code Coverage
   - Build Statistics
   - Last Success/Failure

---

## Complete Plugin Installation Checklist

### During Jenkins Initial Setup (Step 10 in QUICK-START-CHECKLIST.md):

After installing suggested plugins, add these:

**Essential Testing Plugins**:
- [ ] **JUnit** (usually pre-installed)
- [ ] **Code Coverage API**
- [ ] **HTML Publisher Plugin**
- [ ] **Warnings Next Generation**

**Optional Advanced Plugins**:
- [ ] **Performance Plugin** (for load testing)
- [ ] **Dashboard View** (custom dashboards)
- [ ] **Blue Ocean** (modern UI)
- [ ] **Pipeline Stage View** (visual pipeline)
- [ ] **Cobertura Plugin** (alternative coverage)

**Already in your setup**:
- ✅ Docker Pipeline
- ✅ Kubernetes CLI
- ✅ Credentials Binding
- ✅ GitHub Integration

---

## Jenkins UI Navigation After Build

### 1. **Build Page** (`http://YOUR_IP:8080/job/secure-voting-pipeline/BUILD_NUMBER/`)

**Left sidebar links**:
- 📊 **Test Result** → JUnit test summary
- 📈 **Code Coverage** → Coverage metrics
- 📋 **Code Coverage Report** → Interactive HTML coverage
- 🧪 **PyTest Report** → Detailed test results
- ⚠️ **Warnings** → Static analysis issues
- 🐳 **Trivy Scan** → Container security issues

### 2. **Project Page** (`http://YOUR_IP:8080/job/secure-voting-pipeline/`)

**Trend graphs visible**:
- Test Result Trend (pass/fail over 30 builds)
- Code Coverage Trend (line coverage %)
- Warning Trend (issue count over time)
- Build Time Trend

### 3. **Dashboard** (custom view)

Create a dashboard showing:
```
+----------------------------------+----------------------------------+
| Test Pass Rate (Last 10 builds)  | Code Coverage Trend              |
+----------------------------------+----------------------------------+
| Open Warnings (by severity)      | Build Success Rate               |
+----------------------------------+----------------------------------+
| Average Build Time               | Latest Test Failures             |
+----------------------------------+----------------------------------+
```

---

## Quality Gates Configuration

### Example: Fail build if quality drops

Add to Jenkinsfile after test stage:

```groovy
stage('Quality Gates') {
  steps {
    script {
      // Check test results
      def testResults = junit 'ssddlabfinal/src/backend/test-results.xml'
      if (testResults.failCount > 0) {
        error "Tests failed: ${testResults.failCount} failures"
      }
      
      // Check code coverage
      def coverage = readFile('ssddlabfinal/src/backend/coverage.xml')
      // Parse and check if coverage < 80%
      
      // Check warnings
      recordIssues(
        tool: pyLint(pattern: 'ssddlabfinal/src/backend/ruff-report.json'),
        qualityGates: [
          [threshold: 50, type: 'TOTAL', unstable: true],      // Mark unstable if >50 issues
          [threshold: 100, type: 'TOTAL', unstable: false]     // Fail if >100 issues
        ]
      )
    }
  }
}
```

---

## Email Notifications for Test Failures

Add to Jenkinsfile (requires Email Extension Plugin):

```groovy
post {
  failure {
    emailext(
      subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
      body: """
        Build failed!
        
        Project: ${env.JOB_NAME}
        Build: ${env.BUILD_NUMBER}
        URL: ${env.BUILD_URL}
        
        Check console output: ${env.BUILD_URL}console
        Test results: ${env.BUILD_URL}testReport
        Coverage: ${env.BUILD_URL}coverage
      """,
      to: "your-email@example.com"
    )
  }
  unstable {
    emailext(
      subject: "Build Unstable: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
      body: "Build succeeded but quality gates failed. Check warnings.",
      to: "your-email@example.com"
    )
  }
}
```

---

## Viewing Reports

### After successful build:

1. **Test Results**:
   ```
   Build Page → Test Result
   - Total: 2 tests
   - Passed: 2 (100%)
   - Failed: 0
   - Skipped: 0
   - Duration: 0.5s
   ```

2. **Code Coverage**:
   ```
   Build Page → Code Coverage Report
   - Line Coverage: 85%
   - Branch Coverage: 78%
   - Files: 8 covered
   - Click file names to see line-by-line coverage
   ```

3. **Static Analysis**:
   ```
   Build Page → Warnings
   - Total Issues: 15
   - New Issues: 2
   - Fixed Issues: 3
   - By Priority:
     - High: 0
     - Normal: 10
     - Low: 5
   ```

4. **Security Scan**:
   ```
   Console Output → Search "Trivy"
   - Critical: 0
   - High: 0
   - Medium: 2
   - Low: 5
   ```

---

## Trend Analysis

### Track improvement over time:

**Week 1**: 
- Test coverage: 65%
- Warnings: 120
- Build time: 50 minutes

**Week 4**:
- Test coverage: 85% ↑
- Warnings: 15 ↓
- Build time: 40 minutes ↓

Jenkins automatically generates trend graphs showing these improvements.

---

## Best Practices

### 1. **Always publish reports** (even on failure)
```groovy
post {
  always {
    junit allowEmptyResults: true, testResults: '**/test-results.xml'
    publishCoverage adapters: [coberturaAdapter('coverage.xml')]
  }
}
```

### 2. **Set meaningful quality gates**
- Don't fail build for minor warnings
- Use `unstable: true` for soft limits
- Use `unstable: false` for hard limits

### 3. **Keep historical data**
- Jenkins keeps trends for last 30 builds (configurable)
- Archive important reports with `archiveArtifacts`

### 4. **Use HTML reports for detailed analysis**
- Coverage: Click through to see uncovered lines
- PyTest: See assertion failures with full context
- Bandit: See security issue locations in code

---

## Quick Reference: Plugin Commands

| Plugin | Jenkinsfile Command | Output Location |
|--------|---------------------|-----------------|
| JUnit | `junit testResults: 'test-results.xml'` | Build → Test Result |
| Coverage | `publishCoverage adapters: [coberturaAdapter('coverage.xml')]` | Build → Code Coverage |
| HTML Publisher | `publishHTML([reportDir: 'htmlcov', ...])` | Build → HTML Reports |
| Warnings NG | `recordIssues(tool: pyLint(...))` | Build → Warnings |
| Artifacts | `archiveArtifacts artifacts: '*.jar'` | Build → Artifacts |

---

## Next Steps

1. ✅ Install required plugins (Step 11 in QUICK-START-CHECKLIST.md)
2. ✅ Updated Jenkinsfile already includes test/coverage publishing
3. ✅ Run first build with all parameters enabled
4. ✅ Check build page for Test Results, Coverage, Warnings links
5. ✅ Create custom dashboard view (optional)
6. ✅ Set up email notifications (optional)

**Your reports will be available at**:
- `http://YOUR_IP:8080/job/secure-voting-pipeline/BUILD_NUMBER/testReport/`
- `http://YOUR_IP:8080/job/secure-voting-pipeline/BUILD_NUMBER/coverage/`
- `http://YOUR_IP:8080/job/secure-voting-pipeline/BUILD_NUMBER/Code_Coverage_Report/`
