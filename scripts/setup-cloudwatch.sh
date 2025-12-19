#!/bin/bash
# CloudWatch Logs Agent Setup Script

set -e

echo "=== CloudWatch Logs Agent Setup ==="

echo "NOTE: CloudWatch requires IAM role. Skipping for simplified setup."
echo "Logs available via: journalctl, /var/log/, kubectl logs"
exit 0

# Check if already installed
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "✓ CloudWatch agent already running. Skipping installation."
    exit 0
fi

# Install CloudWatch agent
if [ ! -f /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then
    echo "Installing CloudWatch agent..."
    cd /tmp
    wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    sudo dpkg -i amazon-cloudwatch-agent.deb
    rm amazon-cloudwatch-agent.deb
else
    echo "✓ CloudWatch agent already installed"
fi

# Create configuration directory
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

# Create configuration file
echo "Creating CloudWatch agent configuration..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json > /dev/null <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/voting-system/syslog",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "/aws/ec2/voting-system/auth",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/lib/jenkins/logs/jenkins.log",
            "log_group_name": "/aws/ec2/voting-system/jenkins",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 14
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "/aws/ec2/voting-system/docker",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "VotingSystem/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"}
        ],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
        ],
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Enable auto-start
sudo systemctl enable amazon-cloudwatch-agent

# Verify status
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "✓ CloudWatch agent running successfully"
else
    echo "ERROR: CloudWatch agent failed to start"
    sudo systemctl status amazon-cloudwatch-agent
    exit 1
fi

echo "=== CloudWatch setup complete ==="
