#!/bin/bash
# UFW Firewall Setup Script

set -e

echo "=== UFW Firewall Setup ==="

# Check if UFW is already configured
if sudo ufw status | grep -q "Status: active"; then
    echo "✓ UFW already active. Skipping configuration."
    sudo ufw status numbered
    exit 0
fi

# Install UFW
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW..."
    sudo apt-get update
    sudo apt-get install -y ufw
fi

echo "Configuring UFW firewall rules..."

# Set default policies
sudo ufw --force default deny incoming
sudo ufw --force default allow outgoing

# Allow SSH (CRITICAL)
sudo ufw allow 22/tcp comment 'SSH'

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Allow Jenkins
sudo ufw allow 8080/tcp comment 'Jenkins UI'

# Allow application ports
sudo ufw allow 8000/tcp comment 'Backend API'
sudo ufw allow 3000/tcp comment 'Grafana'
sudo ufw allow 5173/tcp comment 'Frontend Dev'
sudo ufw allow 9090/tcp comment 'Prometheus'

# Allow Kubernetes NodePort range
sudo ufw allow 30000:32767/tcp comment 'Kubernetes NodePort'

# Allow internal networking
sudo ufw allow from 10.0.0.0/16 comment 'Internal VPC'
sudo ufw allow from 172.17.0.0/16 comment 'Docker bridge'
sudo ufw allow from 192.168.49.0/24 comment 'Minikube'

# Enable firewall
echo "Enabling UFW..."
sudo ufw --force enable

# Show status
echo "✓ UFW firewall configured and enabled"
sudo ufw status verbose

echo "=== Firewall setup complete ==="
