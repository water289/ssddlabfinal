#!/bin/bash
# Automatic Security Updates Setup Script

set -e

echo "=== Automatic Security Updates Setup ==="

# Check if already configured
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    echo "✓ Automatic updates already configured. Skipping."
    cat /etc/apt/apt.conf.d/20auto-upgrades
    exit 0
fi

# Install unattended-upgrades
if ! dpkg -l | grep -q unattended-upgrades; then
    echo "Installing unattended-upgrades..."
    sudo apt-get update
    sudo apt-get install -y unattended-upgrades apt-listchanges
fi

# Configure unattended-upgrades
echo "Configuring automatic security updates..."
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

# Enable automatic updates
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Test configuration
echo "Testing unattended-upgrades configuration..."
sudo unattended-upgrades --dry-run --debug 2>&1 | head -20

echo "✓ Automatic security updates configured"
echo "=== Auto-updates setup complete ==="
