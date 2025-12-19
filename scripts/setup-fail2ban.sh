#!/bin/bash
# Fail2Ban Setup Script for SSH protection

set -e

echo "=== Fail2Ban Setup ==="

# Check if already running
if systemctl is-active --quiet fail2ban; then
    echo "✓ Fail2Ban already running. Skipping configuration."
    sudo fail2ban-client status
    exit 0
fi

# Install Fail2Ban
if ! command -v fail2ban-client &> /dev/null; then
    echo "Installing Fail2Ban..."
    sudo apt-get update
    sudo apt-get install -y fail2ban
fi

# Create custom configuration
echo "Configuring Fail2Ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[jenkins]
enabled = true
port = 8080
logpath = /var/lib/jenkins/logs/jenkins.log
maxretry = 5
bantime = 1800
EOF

# Start and enable Fail2Ban
echo "Starting Fail2Ban service..."
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Verify status
if systemctl is-active --quiet fail2ban; then
    echo "✓ Fail2Ban running successfully"
    sudo fail2ban-client status
    sudo fail2ban-client status sshd
else
    echo "ERROR: Fail2Ban failed to start"
    sudo systemctl status fail2ban
    exit 1
fi

echo "=== Fail2Ban setup complete ==="
