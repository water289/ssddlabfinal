#!/bin/bash
# SSH Hardening Script - Key-only authentication

set -e

echo "=== SSH Hardening ==="

# Backup original sshd_config
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    echo "Backing up original SSH configuration..."
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi

# Check current configuration
if sudo grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo "✓ SSH already hardened (password authentication disabled)"
    exit 0
fi

echo "Hardening SSH configuration..."

# Disable password authentication
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Additional hardening
sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#*MaxSessions.*/MaxSessions 2/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Test configuration
echo "Testing SSH configuration..."
sudo sshd -t || {
    echo "ERROR: SSH configuration test failed. Restoring backup..."
    sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    exit 1
}

# Restart SSH service
echo "Restarting SSH service..."
sudo systemctl restart sshd

# Verify configuration
echo "✓ SSH hardened successfully"
echo "Configuration summary:"
sudo grep -E "^PasswordAuthentication|^PubkeyAuthentication|^PermitRootLogin" /etc/ssh/sshd_config

echo "=== SSH hardening complete ==="
