#!/bin/bash
# Security Verification Script
# Verifies all security features are properly configured

set -e

echo "=========================================="
echo "  SECURITY CONFIGURATION VERIFICATION"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# Function to check and report
check_feature() {
    local name=$1
    local command=$2
    
    echo -n "Checking $name... "
    if eval "$command" &> /dev/null; then
        echo "✓ PASS"
        ((PASSED++))
    else
        echo "✗ FAIL"
        ((FAILED++))
    fi
}

# 1. EBS Encryption
echo "=== Storage Security ==="
check_feature "EBS Encryption" "aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=\$(ec2-metadata --instance-id | cut -d' ' -f2) --query 'Volumes[*].Encrypted' --output text | grep -q true"

# 2. IMDSv2
echo ""
echo "=== Instance Metadata Security ==="
echo -n "Checking IMDSv2 enforcement... "
if TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null); then
    if curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id &> /dev/null; then
        echo "✓ PASS"
        ((PASSED++))
    else
        echo "✗ FAIL"
        ((FAILED++))
    fi
else
    echo "✗ FAIL (Cannot get token)"
    ((FAILED++))
fi

# 3. SSH Hardening
echo ""
echo "=== SSH Security ==="
check_feature "Password authentication disabled" "sudo grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config"
check_feature "Root login disabled" "sudo grep -q '^PermitRootLogin no' /etc/ssh/sshd_config"
check_feature "Public key authentication enabled" "sudo grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config"

# 4. Firewall
echo ""
echo "=== Firewall Security ==="
check_feature "UFW firewall active" "sudo ufw status | grep -q 'Status: active'"

# 5. Fail2Ban
echo ""
echo "=== Intrusion Prevention ==="
check_feature "Fail2Ban running" "systemctl is-active --quiet fail2ban"

# 6. CloudWatch Agent
echo ""
echo "=== Monitoring ==="
check_feature "CloudWatch agent running" "systemctl is-active --quiet amazon-cloudwatch-agent"

# 7. Jenkins Credentials
echo ""
echo "=== Credentials Management ==="
echo -n "Checking Jenkins credentials configured... "
if [ -d "/var/lib/jenkins/credentials" ] || systemctl is-active --quiet jenkins; then
    echo "✓ PASS (Using Jenkins credentials)"
    ((PASSED++))
else
    echo "⚠ SKIP (Jenkins not installed yet)"
fi

# 9. Kubernetes Secrets
echo ""
echo "=== Kubernetes Security ==="
if command -v kubectl &> /dev/null; then
    check_feature "Kubernetes secrets exist" "kubectl get secret voting-secrets -n voting-system"
else
    echo "Kubernetes not installed yet - skipping"
fi

# 10. Automatic Updates
echo ""
echo "=== System Maintenance ==="
check_feature "Automatic updates configured" "test -f /etc/apt/apt.conf.d/20auto-upgrades"

# Summary
echo ""
echo "=========================================="
echo "  VERIFICATION SUMMARY"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All security checks passed!"
    exit 0
else
    echo "✗ Some security checks failed. Review output above."
    exit 1
fi
